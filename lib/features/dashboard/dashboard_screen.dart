import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../models/bank_account.dart';
import '../../services/storage_service.dart';
import '../../services/fake_bank_service.dart';
import '../../core/utils/insight_engine.dart';

import '../bank/connect_bank_screen.dart';
import '../add_expense/add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Expense> expenses = [];
  List<BankAccount> banks = [];

  double budget = 0;
  int days = 30;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    expenses = await StorageService.getExpenses();
    budget = await StorageService.getBudget();
    days = await StorageService.getBudgetDays();
    setState(() {});
  }

  double get total =>
      expenses.fold(0.0, (s, e) => s + e.amount);

  double get totalBank =>
      banks.fold(0.0, (s, b) => s + b.balance);

  BankAccount? get active {
    try {
      return banks.firstWhere((b) => b.isActive);
    } catch (_) {
      return banks.isNotEmpty ? banks.first : null;
    }
  }

  /// ================= BANK =================

  Future<void> connectBank() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ConnectBankScreen()),
    );

    if (result != null) {
      final acc = result as BankAccount;

      setState(() {
        banks.add(
          acc.copyWith(isActive: banks.isEmpty),
        );
      });
    }
  }

  void setActive(String id) {
    setState(() {
      banks = banks
          .map((b) =>
              b.copyWith(isActive: b.id == id))
          .toList();
    });
  }

  void unlink(String id) {
    setState(() {
      banks.removeWhere((b) => b.id == id);
    });
  }

  Future<void> refresh(String id) async {
    final newBalance =
        await FakeBankService.refreshBalance();

    setState(() {
      banks = banks.map((b) {
        return b.id == id
            ? b.copyWith(balance: newBalance)
            : b;
      }).toList();
    });
  }

  /// ================= EXPENSE =================

  void editExpense(Expense e) async {
    final name = TextEditingController(text: e.name);
    final amount =
        TextEditingController(text: e.amount.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa chi tiêu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            TextField(
              controller: amount,
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
      await StorageService.updateExpense(
        Expense(
          id: e.id,
          name: name.text,
          amount:
              double.tryParse(amount.text) ?? 0,
          category: e.category,
        ),
      );
      load();
    }
  }

  /// ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final source =
        banks.isNotEmpty ? (active?.balance ?? totalBank) : budget;

    final remaining = source - total;

    final insights = InsightEngine.analyze(
      budget: source,
      total: total,
      budgetDays: days,
      expenses: expenses,
    );

    final isDesktop =
        MediaQuery.of(context).size.width > 800;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddExpenseScreen()),
          );
          load();
        },
        child: const Icon(Icons.add),
      ),

      body: Row(
        children: [

          /// SIDEBAR (WEB)
          if (isDesktop)
            Container(
              width: 220,
              color: const Color(0xFF0F172A),
              child: Column(
                children: const [
                  SizedBox(height: 40),
                  Text("Finance",
                      style:
                          TextStyle(color: Colors.white)),
                ],
              ),
            ),

          /// MAIN
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                /// BALANCE CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6)
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text("Total Balance",
                          style: TextStyle(
                              color: Colors.white70)),
                      Text(
                        "${source.toStringAsFixed(0)}đ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// BANK LIST
                ...banks.map((b) => Card(
                      child: ListTile(
                        title: Text(b.bankName),
                        subtitle: Text(b.accountNumber),
                        trailing: Column(
                          children: [
                            Text(
                                "${b.balance.toStringAsFixed(0)}"),
                            PopupMenuButton(
                              onSelected: (v) {
                                if (v == "refresh")
                                  refresh(b.id);
                                if (v == "unlink")
                                  unlink(b.id);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: "refresh",
                                    child: Text("Refresh")),
                                const PopupMenuItem(
                                    value: "unlink",
                                    child: Text("Huỷ")),
                              ],
                            )
                          ],
                        ),
                        onTap: () => setActive(b.id),
                      ),
                    )),

                ElevatedButton(
                  onPressed: connectBank,
                  child: const Text("Thêm ngân hàng"),
                ),

                const SizedBox(height: 16),

                /// INSIGHT
                ...insights.map((i) => Container(
                      margin:
                          const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Text(i),
                    )),

                const SizedBox(height: 16),

                /// EXPENSE LIST
                ...expenses.map((e) => ListTile(
                      title: Text(e.name),
                      trailing: Text(
                          "-${e.amount.toStringAsFixed(0)}"),
                      onTap: () => editExpense(e),
                      onLongPress: () async {
                        await StorageService.deleteExpense(
                            e.id);
                        load();
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}