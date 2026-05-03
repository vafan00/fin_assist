import 'package:flutter/material.dart';

class LeftoverCard extends StatelessWidget {
  final double remaining;
  final int daysLeft;

  const LeftoverCard({
    super.key,
    required this.remaining,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final daily = daysLeft == 0 ? 0 : remaining / daysLeft;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bạn còn", style: TextStyle(color: Colors.white70)),
          Text(
            "${remaining.toStringAsFixed(0)}đ",
            style: const TextStyle(fontSize: 30, color: Colors.white),
          ),
          Text("$daysLeft ngày còn lại"),
          Text("≈ ${daily.toStringAsFixed(0)}đ/ngày",
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}