import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/expense_model.dart';
import '../../../core/utils/category_colors.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> data = {};

    for (var e in expenses) {
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }

    final total = data.values.fold(0.0, (a, b) => a + b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PieChart(
        PieChartData(
          sections: data.entries.map((e) {
            return PieChartSectionData(
              value: e.value,
              color: categoryColors[e.key],
              title: "",
            );
          }).toList(),
        ),
      ),
    );
  }
}