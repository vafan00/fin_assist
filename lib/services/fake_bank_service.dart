import 'dart:math';
import '../models/bank_account.dart';

class FakeBankService {
  static final _rand = Random();

  /// 🔗 CONNECT
  static Future<BankAccount> connectBank(String bank) async {
    await Future.delayed(const Duration(seconds: 1));

    return BankAccount(
      id: _generateId(), // ✅ fix trùng ID
      bankName: bank,
      accountNumber: _generateAccount(),
      balance: _generateBalance(),
      isActive: false,
    );
  }

  /// 🔄 REFRESH
  static Future<double> refreshBalance() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _generateBalance();
  }

  /// ================= PRIVATE =================

  static String _generateId() {
    return "${DateTime.now().millisecondsSinceEpoch}_${_rand.nextInt(9999)}";
  }

  static String _generateAccount() {
    return "****${1000 + _rand.nextInt(9000)}";
  }

  static double _generateBalance() {
    return (5000000 + _rand.nextInt(10000000)).toDouble(); // ✅ fix double
  }
}