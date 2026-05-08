import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../models/bank_account.dart';
import '../../services/storage_service.dart';
import '../../services/fake_bank_service.dart';
import '../../core/utils/insight_engine.dart';
import '../bank/connect_bank_screen.dart';
import '../add_expense/add_expense_screen.dart';

// ─── Brand Colors ────────────────────────────────────────────────
const kGreen      = Color(0xFF00C896);
const kGreenDark  = Color(0xFF00A87E);
const kGreenLight = Color(0xFFE6F9F4);
const kSurface    = Color(0xFFF7FAF7);
const kCard       = Colors.white;

// ─── Responsive Helper ───────────────────────────────────────────
// Breakpoints:
//   mobile  < 600 px
//   tablet  600 – 1024 px
//   desktop > 1024 px
class R {
  final double width;
  R(this.width);

  static R of(BuildContext ctx) => R(MediaQuery.of(ctx).size.width);

  bool get isMobile  => width < 600;
  bool get isTablet  => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;

  T pick<T>({required T mobile, required T tablet, required T desktop}) {
    if (isDesktop) return desktop;
    if (isTablet)  return tablet;
    return mobile;
  }

  double get hPad        => pick(mobile: 16, tablet: 32, desktop: 40);
  double get donutSize   => pick(mobile: 180, tablet: 200, desktop: 220);
  double get headerTop   => pick(mobile: 52, tablet: 40, desktop: 36);
  double get donutFont   => pick(mobile: 26, tablet: 28, desktop: 32);
  int    get accountCols => pick(mobile: 1, tablet: 2, desktop: 3);
  double get sidebarW    => isTablet ? 72 : 220;
}

// ─────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Expense>     expenses = [];
  List<BankAccount> banks    = [];
  double budget = 0;
  int    days   = 30;
  int    _tab   = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    expenses = await StorageService.getExpenses();
    budget   = await StorageService.getBudget();
    days     = await StorageService.getBudgetDays();
    setState(() {});
  }

  double get total      => expenses.fold(0.0, (s, e) => s + e.amount);
  double get totalBank  => banks.fold(0.0, (s, b) => s + b.balance);
  double get source     => banks.isNotEmpty ? (active?.balance ?? totalBank) : budget;
  double get remaining  => source - total;
  double get spentRatio => source > 0 ? (total / source).clamp(0.0, 1.0) : 0;

  BankAccount? get active {
    try   { return banks.firstWhere((b) => b.isActive); }
    catch (_) { return banks.isNotEmpty ? banks.first : null; }
  }

  // ─── Bank ────────────────────────────────────────────────────

  Future<void> connectBank() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConnectBankScreen()),
    );
    if (result != null) {
      setState(() {
        banks.add((result as BankAccount).copyWith(isActive: banks.isEmpty));
      });
    }
  }

  void setActive(String id) => setState(() {
    banks = banks.map((b) => b.copyWith(isActive: b.id == id)).toList();
  });

  void unlink(String id) => setState(() {
    banks.removeWhere((b) => b.id == id);
  });

  Future<void> refresh(String id) async {
    final bal = await FakeBankService.refreshBalance();
    setState(() {
      banks = banks.map((b) => b.id == id ? b.copyWith(balance: bal) : b).toList();
    });
  }

  // ─── Manual Balance ──────────────────────────────────────────

  Future<void> _inputManualBalance() async {
    final ctrl = TextEditingController(
      text: budget > 0 ? budget.toStringAsFixed(0) : '',
    );
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualBalanceSheet(
        controller: ctrl,
        onSave: (v) async {
          await StorageService.saveBudget(v);
          load();
        },
      ),
    );
  }

  // ─── Edit Expense ────────────────────────────────────────────

  Future<void> editExpense(Expense e) async {
    final name   = TextEditingController(text: e.name);
    final amount = TextEditingController(text: e.amount.toStringAsFixed(0));

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Adjust spending"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _inputField(ctrl: name,   label: "Name"),
            const SizedBox(height: 12),
            _inputField(ctrl: amount, label: "Amount (vnđ)", numeric: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await StorageService.updateExpense(Expense(
        id: e.id, name: name.text,
        amount: double.tryParse(amount.text) ?? 0,
        category: e.category,
      ));
      load();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);

    return Scaffold(
      backgroundColor: kSurface,
      floatingActionButton: (!r.isDesktop && _tab == 0)
          ? FloatingActionButton(
              backgroundColor: kGreen,
              onPressed: _goAddExpense,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: r.isMobile ? _buildBottomNav() : null,
      body: Row(
        children: [
          if (!r.isMobile) _buildSidebar(r),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(r)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(r.hPad, 0, r.hPad, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      _buildAccountsSection(r),
                      const SizedBox(height: 24),
                      _buildInsightsSection(r),
                      const SizedBox(height: 24),
                      _buildExpenseSection(r),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen()),
    );
    load();
  }

  // ═══════════════════════════════════════════════════════════════
  //  SIDEBAR  (tablet = icon only, desktop = full label)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSidebar(R r) {
    final iconOnly = r.isTablet;
    final items = [
      _SideItem(icon: Icons.grid_view_rounded,    label: "Overview",  idx: 0),
      _SideItem(icon: Icons.receipt_long_outlined, label: "Transaction", idx: 1),
      _SideItem(icon: Icons.pie_chart_outline,    label: "Budget", idx: 2),
      _SideItem(icon: Icons.person_outline,       label: "Profile",       idx: 3),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: r.sidebarW,
      color: const Color(0xFF0D2B22),
      child: Column(
        children: [
          SizedBox(height: r.headerTop + 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: iconOnly
                ? const Icon(Icons.account_balance_wallet, color: kGreen, size: 28)
                : const Column(children: [
                    Icon(Icons.account_balance_wallet, color: kGreen, size: 32),
                    SizedBox(height: 6),
                    Text("Fin Assist",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          ...items.map((item) => _sidebarItem(item, iconOnly)),
          const Spacer(),
          if (!iconOnly)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _goAddExpense,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Expense"),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: IconButton(
                onPressed: _goAddExpense,
                icon: const Icon(Icons.add_circle, color: kGreen, size: 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sidebarItem(_SideItem item, bool iconOnly) {
    final active = _tab == item.idx;
    return InkWell(
      onTap: () => setState(() => _tab = item.idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kGreen.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: iconOnly
            ? Center(child: Icon(item.icon, color: active ? kGreen : Colors.white54, size: 22))
            : Row(children: [
                Icon(item.icon, color: active ? kGreen : Colors.white54, size: 20),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: active ? kGreen : Colors.white70,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(R r) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kGreen, kGreenDark],
        ),
      ),
      padding: EdgeInsets.fromLTRB(r.hPad, r.headerTop, r.hPad, 28),
      child: r.isDesktop ? _headerDesktop(r) : _headerMobileTablet(r),
    );
  }

  // Desktop: Donut kLeft + summary cards right
  Widget _headerDesktop(R r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDonut(r),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "IN MY POCKET",
                style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _summaryCard("Total balance", _fmtFull(source), icon: Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 12),
                  _summaryCard("Paid", _fmtFull(total), icon: Icons.remove_circle_outline, negative: true),
                  const SizedBox(width: 12),
                  _summaryCard("Remaining", _fmtFull(remaining), icon: Icons.savings_outlined, negative: remaining < 0),
                ],
              ),
              const SizedBox(height: 20),
              _progressBar(),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  // Mobile / Tablet: stacked
  Widget _headerMobileTablet(R r) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "IN MY POCKET",
              style: TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDonut(r),
        const SizedBox(height: 20),
        if (r.isTablet) ...[_progressBar(), const SizedBox(height: 16)],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statChip("Balance",  _fmt(source)),
            _divider(),
            _statChip("Expense", _fmt(total)),
            _divider(),
            _statChip("Remaining",  _fmt(remaining),
                color: remaining < 0 ? Colors.redAccent[100]! : Colors.white),
          ],
        ),
      ],
    );
  }

  Widget _buildDonut(R r) {
    final size = r.donutSize;
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _DonutPainter(ratio: spentRatio)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Available",
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(
                _fmt(remaining < 0 ? 0 : remaining),
                style: TextStyle(color: Colors.white, fontSize: r.donutFont, fontWeight: FontWeight.bold),
              ),
              const Text("vnđ", style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${(spentRatio * 100).toStringAsFixed(0)}% used",
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text("${_fmtFull(remaining)} remaining",
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: spentRatio,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(
              spentRatio > 0.8 ? Colors.orangeAccent : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, {required IconData icon, bool negative = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                  color: negative ? Colors.redAccent[100] : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, {Color color = Colors.white}) => Column(
    children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );

  Widget _divider() => Container(width: 0.5, height: 28, color: Colors.white30);

  // ═══════════════════════════════════════════════════════════════
  //  ACCOUNTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAccountsSection(R r) {
    final items = [
      ...banks.map((b) => _buildBankCard(b)),
      if (banks.isEmpty) _buildManualBalanceCard(),
      _buildAddBankButton(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Account"),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: r.accountCols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: r.pick(mobile: 4.0, tablet: 2.6, desktop: 2.8),
          children: items,
        ),
      ],
    );
  }

  Widget _buildBankCard(BankAccount b) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: b.isActive ? kGreen : Colors.transparent,
          width: b.isActive ? 1.5 : 0,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.account_balance, color: kGreen, size: 20),
        ),
        title: Text(b.bankName,       style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(b.accountNumber, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_fmt(b.balance),
                style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 13)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
              onSelected: (v) {
                if (v == "refresh") refresh(b.id);
                if (v == "unlink")  unlink(b.id);
                if (v == "active")  setActive(b.id);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: "active",  child: Text("Set main")),
                PopupMenuItem(value: "refresh", child: Text("Refresh")),
                PopupMenuItem(value: "unlink",  child: Text("Unlink")),
              ],
            ),
          ],
        ),
        onTap: () => setActive(b.id),
      ),
    );
  }

  Widget _buildManualBalanceCard() {
    return GestureDetector(
      onTap: _inputManualBalance,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance_wallet, color: kGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Enter Manual", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    budget > 0 ? "${_fmtFull(budget)}vnđ" : "Not Set — press to update",
                    style: TextStyle(
                      color: budget > 0 ? kGreen : Colors.grey,
                      fontSize: 11,
                      fontWeight: budget > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: kGreen, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBankButton() {
    return GestureDetector(
      onTap: connectBank,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kGreen, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: kGreen, size: 18),
            SizedBox(width: 6),
            Text("Link your bank account",
                style: TextStyle(color: kGreen, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INSIGHTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInsightsSection(R r) {
    final insights = InsightEngine.analyze(
      budget: source, total: total, budgetDays: days, expenses: expenses,
    );
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Analysis"),
        const SizedBox(height: 12),
        if (r.isDesktop)
          Row(
            children: insights.asMap().entries.map((entry) {
              return [
                Expanded(child: _insightChip(entry.value)),
                if (entry.key < insights.length - 1) const SizedBox(width: 12),
              ];
            }).expand((e) => e).toList(),
          )
        else
          ...insights.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _insightChip(i),
              )),
      ],
    );
  }

  Widget _insightChip(String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: kGreenLight, borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        const Icon(Icons.lightbulb_outline, color: kGreen, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: kGreenDark, fontSize: 13))),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  EXPENSES
  // ═══════════════════════════════════════════════════════════════

  Widget _buildExpenseSection(R r) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Recent spending"),
        const SizedBox(height: 12),
        if (r.isDesktop)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 4.0,
            children: expenses.map(_expenseCard).toList(),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: expenses.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Column(
                  children: [
                    _expenseTile(e),
                    if (i < expenses.length - 1)
                      const Divider(height: 0, indent: 68, endIndent: 16, thickness: 0.5),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _expenseCard(Expense e) {
    return GestureDetector(
      onTap: () => editExpense(e),
      onLongPress: () async { await StorageService.deleteExpense(e.id); load(); },
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _catColor(e.category).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_catIcon(e.category), color: _catColor(e.category), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(e.category ?? "Other", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Text("-${e.amount.toStringAsFixed(0)}vnđ",
                style: const TextStyle(color: Color(0xFFE85454), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _expenseTile(Expense e) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _catColor(e.category).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_catIcon(e.category), color: _catColor(e.category), size: 20),
      ),
      title:    Text(e.name,            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(e.category ?? "Khác", style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Text(
        "-${e.amount.toStringAsFixed(0)}vnđ",
        style: const TextStyle(color: Color(0xFFE85454), fontWeight: FontWeight.bold, fontSize: 13),
      ),
      onTap: () => editExpense(e),
      onLongPress: () async { await StorageService.deleteExpense(e.id); load(); },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM NAV  (mobile only)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kGreen,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 12,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded),    label: "Overview"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: "Transaction"),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline),    label: "Budget"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline),       label: "Profile"),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
  );

  Widget _inputField({required TextEditingController ctrl, required String label, bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGreen),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(1)}M";
    if (v >= 1000)    return "${(v / 1000).toStringAsFixed(0)}K";
    return v.toStringAsFixed(0);
  }

  String _fmtFull(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  Color _catColor(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'Foods':   return Colors.orange;
      case 'Shopping':   return Colors.purple;
      case 'Bills':   return Colors.blue;
      case 'Travel': return Colors.teal;
      default:           return kGreen;
    }
  }

  IconData _catIcon(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'Foods':   return Icons.restaurant_outlined;
      case 'Shopping':   return Icons.shopping_bag_outlined;
      case 'Bills':   return Icons.receipt_outlined;
      case 'Travel': return Icons.directions_car_outlined;
      default:           return Icons.attach_money;
    }
  }
}

// ─── Sidebar model ───────────────────────────────────────────────
class _SideItem {
  final IconData icon;
  final String   label;
  final int      idx;
  const _SideItem({required this.icon, required this.label, required this.idx});
}

// ═══════════════════════════════════════════════════════════════════
//  MANUAL BALANCE SHEET
// ═══════════════════════════════════════════════════════════════════

class _ManualBalanceSheet extends StatelessWidget {
  final TextEditingController controller;
  final Function(double)       onSave;
  const _ManualBalanceSheet({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Enter Manual",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Your current account balance",
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kGreen),
            decoration: InputDecoration(
              hintText: "0",
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 32),
              suffixText: "vnđ",
              suffixStyle: const TextStyle(color: kGreen, fontSize: 20, fontWeight: FontWeight.bold),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kGreen)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kGreen, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final v = double.tryParse(controller.text) ?? 0;
                if (v > 0) { onSave(v); Navigator.pop(context); }
              },
              child: const Text("Save balance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DONUT PAINTER
// ═══════════════════════════════════════════════════════════════════

class _DonutPainter extends CustomPainter {
  final double ratio;
  _DonutPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center  = Offset(size.width / 2, size.height / 2);
    final radius  = size.width / 2 - 18;
    const strokeW = 18.0;

    canvas.drawCircle(center, radius,
      Paint()..color = Colors.white.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = strokeW);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, 2 * pi * ratio, false,
      Paint()
        ..color     = ratio > 0.8 ? Colors.orangeAccent : Colors.yellowAccent.shade700
        ..style     = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    if (ratio < 1.0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + 2 * pi * ratio,
        2 * pi * (1 - ratio) - 0.02,
        false,
        Paint()
          ..color     = Colors.white
          ..style     = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.ratio != ratio;
}