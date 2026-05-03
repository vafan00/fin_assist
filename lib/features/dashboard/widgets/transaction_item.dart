import 'package:flutter/material.dart';
import '../../../models/expense_model.dart';

class TransactionItem extends StatelessWidget {
  final Expense expense;
  final Function() onDelete;
  final Function() onEdit;

  const TransactionItem({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(expense.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("-${expense.amount.toStringAsFixed(0)}đ"),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}