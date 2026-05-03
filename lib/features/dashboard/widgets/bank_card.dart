import 'package:flutter/material.dart';
import '../../../models/bank_account.dart';

class BankCard extends StatelessWidget {
  final BankAccount account;
  final VoidCallback onRefresh;
  final VoidCallback onUnlink;
  final VoidCallback onChange;

  const BankCard({
    super.key,
    required this.account,
    required this.onRefresh,
    required this.onUnlink,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.indigo],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.bankName,
                style: const TextStyle(color: Colors.white),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "change") onChange();
                  if (value == "unlink") onUnlink();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: "change",
                    child: Text("Đổi ngân hàng"),
                  ),
                  const PopupMenuItem(
                    value: "unlink",
                    child: Text("Huỷ liên kết"),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 8),

          Text(
            account.accountNumber,
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 12),

          Text(
            "${account.balance.toStringAsFixed(0)}đ",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh,
                  color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}