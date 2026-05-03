class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final double balance;
  final bool isActive;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.balance,
    this.isActive = false,
  });

  BankAccount copyWith({
    double? balance,
    bool? isActive,
  }) {
    return BankAccount(
      id: id,
      bankName: bankName,
      accountNumber: accountNumber,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
    );
  }
}