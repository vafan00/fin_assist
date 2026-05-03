import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../services/storage_service.dart';

class AddExpenseScreen extends StatelessWidget {
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm chi tiêu")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameCtrl),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () async {
                final e = Expense(
                  id: DateTime.now().toString(),
                  name: nameCtrl.text,
                  amount: double.tryParse(amountCtrl.text) ?? 0,
                  category: "Other",
                );

                await StorageService.addExpense(e);
                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            )
          ],
        ),
      ),
    );
  }
}