class InsightEngine {
  static List<String> analyze({
    required double budget,
    required double total,
    required int budgetDays,
    required List expenses,
  }) {
    List<String> insights = [];

    if (total > budget * 0.8) {
      insights.add("⚠️ Bạn tiêu quá 80% ngân sách");
    }

    if (expenses.length > 5) {
      insights.add("📊 Nhiều giao dịch gần đây");
    }

    if (budget > 0) {
      final daily = total / DateTime.now().day;
      if (daily > budget / budgetDays) {
        insights.add("🔥 Bạn đang tiêu nhanh hơn dự kiến");
      }
    }

    return insights;
  }
}