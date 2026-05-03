import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final String icon;
  final double amount;

  const CategoryItem({super.key, 
    required this.title,
    required this.icon,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 167, 167),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$icon $title"),
          Text("-${amount.toStringAsFixed(0)}đ"),
        ],
      ),
    );
  }
}