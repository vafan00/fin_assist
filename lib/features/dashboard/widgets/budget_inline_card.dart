import 'package:flutter/material.dart';

class BudgetInlineCard extends StatefulWidget {
  final double budget;
  final int days;
  final Function(double budget, int days) onSave;

  const BudgetInlineCard({
    super.key,
    required this.budget,
    required this.days,
    required this.onSave,
  });

  @override
  State<BudgetInlineCard> createState() => _BudgetInlineCardState();
}

class _BudgetInlineCardState extends State<BudgetInlineCard> {
  bool isEditing = false;

  late TextEditingController budgetCtrl;
  late TextEditingController daysCtrl;

  @override
  void initState() {
    super.initState();
    budgetCtrl =
        TextEditingController(text: widget.budget.toStringAsFixed(0));
    daysCtrl =
        TextEditingController(text: widget.days.toString());
  }

  void toggleEdit() {
    setState(() => isEditing = !isEditing);
  }

  void save() {
    final b = double.tryParse(budgetCtrl.text) ?? 0;
    final d = int.tryParse(daysCtrl.text) ?? 30;

    widget.onSave(b, d);
    setState(() => isEditing = false);
  }

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
      child: isEditing ? _buildEdit() : _buildView(),
    );
  }

  Widget _buildView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ngân sách"),
            Text(
              "${widget.budget.toStringAsFixed(0)}đ / ${widget.days} ngày",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        IconButton(
          onPressed: toggleEdit,
          icon: const Icon(Icons.edit),
        )
      ],
    );
  }

  Widget _buildEdit() {
    return Column(
      children: [
        TextField(
          controller: budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Ngân sách"),
        ),
        TextField(
          controller: daysCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Số ngày"),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: save,
                child: const Text("Lưu"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: toggleEdit,
                child: const Text("Huỷ"),
              ),
            ),
          ],
        )
      ],
    );
  }
}