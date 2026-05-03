import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final double budget;
  final Function() onEdit;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ngân sách"),
              Text(
                "${budget.toStringAsFixed(0)}đ",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
          )
        ],
      ),
    );
  }
}