import '../models/expense_model.dart';

class StorageService {
  static final List<Expense> _expenses = [];

  static double _budget = 0;
  static int _days = 30;

  /// ================= EXPENSE =================

  static Future<List<Expense>> getExpenses() async {
    return List.from(_expenses); // ✅ tránh mutate trực tiếp
  }

  static Future<void> addExpense(Expense e) async {
    _expenses.add(e);
  }

  static Future<void> updateExpense(Expense e) async {
    final index =
        _expenses.indexWhere((x) => x.id == e.id);

    if (index != -1) {
      _expenses[index] = e;
    }
  }

  static Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
  }

  /// ================= BUDGET =================

  static Future<double> getBudget() async => _budget;

  static Future<void> saveBudget(double b) async {
    _budget = b;
  }

  static Future<int> getBudgetDays() async => _days;

  static Future<void> saveBudgetDays(int d) async {
    _days = d;
  }
}