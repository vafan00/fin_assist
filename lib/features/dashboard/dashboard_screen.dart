import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../models/bank_account.dart';
import '../../services/storage_service.dart';
import '../../services/fake_bank_service.dart';
import '../../core/utils/insight_engine.dart';

import '../bank/connect_bank_screen.dart';
import '../add_expense/add_expense_screen.dart';

import 'widgets/leftover_card.dart';
import 'widgets/expense_chart.dart';
import 'widgets/budget_inline_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  List<Expense> expenses = [];
  List<BankAccount> bankAccounts = [];

  double budget = 0;
  int budgetDays = 30;

  final ScrollController _scrollController =
      ScrollController();

  bool showFab = true;
  double lastOffset = 0;

  @override
  void initState() {
    super.initState();
    load();

    /// FAB hide/show
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final offset = _scrollController.offset;

      if (offset > lastOffset + 5) {
        if (showFab) setState(() => showFab = false);
      } else if (offset < lastOffset - 5) {
        if (!showFab) setState(() => showFab = true);
      }

      lastOffset = offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    expenses = await StorageService.getExpenses();
    budget = await StorageService.getBudget();
    budgetDays = await StorageService.getBudgetDays();
    setState(() {});
  }

  /// ================= BANK =================

  double get totalBank =>
      bankAccounts.fold(0.0, (sum, b) => sum + b.balance);

  BankAccount? get activeAccount {
    try {
      return bankAccounts.firstWhere((b) => b.isActive);
    } catch (_) {
      return bankAccounts.isNotEmpty
          ? bankAccounts.first
          : null;
    }
  }

  Future<void> connectBank() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ConnectBankScreen()),
    );

    if (result != null) {
      final acc = result as BankAccount;

      setState(() {
        bankAccounts.add(
          acc.copyWith(
              isActive: bankAccounts.isEmpty),
        );
      });
    }
  }

  void setActive(String id) {
    setState(() {
      bankAccounts = bankAccounts.map((b) {
        return b.copyWith(isActive: b.id == id);
      }).toList();
    });
  }

  void unlink(String id) {
    setState(() {
      bankAccounts.removeWhere((b) => b.id == id);

      /// đảm bảo luôn có active
      if (!bankAccounts.any((b) => b.isActive) &&
          bankAccounts.isNotEmpty) {
        bankAccounts[0] =
            bankAccounts[0].copyWith(isActive: true);
      }
    });
  }

  Future<void> refresh(String id) async {
    final newBalance =
        await FakeBankService.refreshBalance();

    setState(() {
      bankAccounts = bankAccounts.map((b) {
        return b.id == id
            ? b.copyWith(balance: newBalance)
            : b;
      }).toList();
    });
  }

  /// ================= EXPENSE =================

  double get totalExpense =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  void _editExpense(Expense e) async {
    final nameCtrl =
        TextEditingController(text: e.name);
    final amountCtrl = TextEditingController(
        text: e.amount.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa chi tiêu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text("Huỷ")),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text("Lưu")),
        ],
      ),
    );

    if (ok == true) {
      final updated = Expense(
        id: e.id,
        name: nameCtrl.text,
        amount:
            double.tryParse(amountCtrl.text) ?? 0,
        category: e.category,
      );

      await StorageService.updateExpense(updated);
      load();
    }
  }

  /// ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final sourceMoney = bankAccounts.isNotEmpty
        ? (activeAccount?.balance ?? totalBank)
        : budget;

    final remaining = sourceMoney - totalExpense;

    final now = DateTime.now();
    final daysLeft =
        (budgetDays - now.day).clamp(0, 999);

    final insights = InsightEngine.analyze(
      budget: sourceMoney,
      total: totalExpense,
      budgetDays: budgetDays,
      expenses: expenses,
    );

    return Scaffold(
      /// FAB animation
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: showFab
            ? const Offset(0, 0)
            : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: showFab ? 1 : 0,
          child: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddExpenseScreen()),
              );
              load();
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),

      body: CustomScrollView(
        controller: _scrollController,
        slivers: [

          /// APP BAR
          const SliverAppBar(
            pinned: true,
            title: Text("Dashboard"),
          ),

          /// HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// TOTAL BALANCE
                  if (bankAccounts.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius:
                            BorderRadius.circular(
                                16),
                      ),
                      child: Column(
                        children: [
                          const Text("Tổng số dư",
                              style: TextStyle(
                                  color:
                                      Colors.white70)),
                          Text(
                            "${totalBank.toStringAsFixed(0)}đ",
                            style:
                                const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  /// BANK LIST
                  ...bankAccounts.map((b) {
                    return GestureDetector(
                      onTap: () => setActive(b.id),
                      child: Opacity(
                        opacity:
                            b.isActive ? 1 : 0.5,
                        child: Container(
                          margin:
                              const EdgeInsets.only(
                                  bottom: 10),
                          padding:
                              const EdgeInsets.all(
                                  16),
                          decoration: BoxDecoration(
                            color: b.isActive
                                ? Colors.blue
                                : Colors.grey
                                    .shade200,
                            borderRadius:
                                BorderRadius
                                    .circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(b.bankName),
                                  Text(
                                      b.accountNumber),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                      "${b.balance.toStringAsFixed(0)}đ"),
                                  PopupMenuButton(
                                    onSelected:
                                        (value) {
                                      if (value ==
                                          "refresh") {
                                        refresh(
                                            b.id);
                                      }
                                      if (value ==
                                          "unlink") {
                                        unlink(
                                            b.id);
                                      }
                                    },
                                    itemBuilder:
                                        (_) => [
                                      const PopupMenuItem(
                                          value:
                                              "refresh",
                                          child: Text(
                                              "Refresh")),
                                      const PopupMenuItem(
                                          value:
                                              "unlink",
                                          child: Text(
                                              "Huỷ")),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  ElevatedButton(
                    onPressed: connectBank,
                    child: const Text(
                        "+ Thêm ngân hàng"),
                  ),

                  /// HERO
                  LeftoverCard(
                    remaining: remaining,
                    daysLeft: daysLeft,
                  ),

                  /// BUDGET fallback
                  if (bankAccounts.isEmpty)
                    BudgetInlineCard(
                      budget: budget,
                      days: budgetDays,
                      onSave: (b, d) async {
                        await StorageService
                            .saveBudget(b);
                        await StorageService
                            .saveBudgetDays(d);
                        load();
                      },
                    ),

                  const SizedBox(height: 16),

                  /// CHART
                  ExpenseChart(expenses: expenses),

                  const SizedBox(height: 16),

                  /// INSIGHT
                  ...insights.map((text) {
                    return Container(
                      margin:
                          const EdgeInsets.only(
                              bottom: 8),
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                                12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons
                              .auto_awesome),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(text)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          /// EXPENSE LIST
          SliverList(
            delegate:
                SliverChildBuilderDelegate(
              (context, index) {
                final e = expenses[index];

                return Dismissible(
                  key: Key(e.id),
                  direction:
                      DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment:
                        Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(
                            right: 20),
                    child: const Icon(
                        Icons.delete,
                        color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await StorageService
                        .deleteExpense(e.id);
                    load();
                  },
                  child: ListTile(
                    title: Text(e.name),
                    subtitle:
                        Text(e.category),
                    trailing: Text(
                        "-${e.amount.toStringAsFixed(0)}đ"),
                    onTap: () =>
                        _editExpense(e),
                  ),
                );
              },
              childCount: expenses.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}