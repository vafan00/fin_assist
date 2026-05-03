import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../services/storage_service.dart';

class AddExpenseScreen extends StatelessWidget {
  AddExpenseScreen({super.key});

  final name = TextEditingController();
  final amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration:
                  const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Amount"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await StorageService.addExpense(
                  Expense(
                    id: DateTime.now().toString(),
                    name: name.text,
                    amount:
                        double.tryParse(amount.text) ?? 0,
                    category: "Other",
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}