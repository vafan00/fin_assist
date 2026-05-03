import 'package:flutter/material.dart';
import '../../services/fake_bank_service.dart';

class ConnectBankScreen extends StatelessWidget {
  ConnectBankScreen({super.key});

  final banks = ["Vietcombank", "Techcombank", "MB Bank"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Chọn ngân hàng")),
      body: ListView.builder(
        itemCount: banks.length,
        itemBuilder: (_, i) {
          final bank = banks[i];

          return ListTile(
            title: Text(bank),
            onTap: () async {
              final acc =
                  await FakeBankService.connectBank(bank);
              Navigator.pop(context, acc);
            },
          );
        },
      ),
    );
  }
}