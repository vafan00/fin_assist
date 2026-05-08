import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/expense_model.dart';
import '../../services/storage_service.dart';

// ─── Brand colors (shared với dashboard) ────────────────────────
const _kGreen      = Color(0xFF00C896);
const _kGreenDark  = Color(0xFF00A87E);
const _kGreenLight = Color(0xFFE6F9F4);
const _kSurface    = Color(0xFFF7FAF7);

// ─── Responsive helper (same breakpoints as dashboard) ──────────
class _R {
  final double width;
  _R(this.width);
  static _R of(BuildContext ctx) => _R(MediaQuery.of(ctx).size.width);
  bool get isMobile  => width < 600;
  bool get isTablet  => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;
}

// ─── Category model ──────────────────────────────────────────────
class _Cat {
  final String   label;
  final IconData icon;
  final Color    color;
  const _Cat({required this.label, required this.icon, required this.color});
}

const _cats = [
  _Cat(label: 'Foods',   icon: Icons.restaurant_outlined,     color: Color(0xFFFF9800)),
  _Cat(label: 'Shopping',   icon: Icons.shopping_bag_outlined,   color: Color(0xFF9C27B0)),
  _Cat(label: 'Bills',   icon: Icons.receipt_outlined,        color: Color(0xFF2196F3)),
  _Cat(label: 'Travel', icon: Icons.directions_car_outlined, color: Color(0xFF009688)),
  _Cat(label: 'Health',  icon: Icons.favorite_outline,        color: Color(0xFFE91E63)),
  _Cat(label: 'Entertainment',  icon: Icons.sports_esports_outlined, color: Color(0xFF673AB7)),
  _Cat(label: 'Study',   icon: Icons.menu_book_outlined,      color: Color(0xFF3F51B5)),
  _Cat(label: 'Other',      icon: Icons.category_outlined,       color: Color(0xFF607D8B)),
];

// ════════════════════════════════════════════════════════════════════
//  Screen entry point — wraps content in correct responsive shell
// ════════════════════════════════════════════════════════════════════

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = _R.of(context);

    // Mobile: full-screen
    if (r.isMobile) {
      return const Scaffold(
        backgroundColor: _kSurface,
        body: _AddExpenseContent(),
      );
    }

    // Tablet: centered card on dimmed background
    if (r.isTablet) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.45),
        body: Center(
          child: Container(
            width: 520,
            margin: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 12))],
            ),
            clipBehavior: Clip.antiAlias,
            child: const _AddExpenseContent(),
          ),
        ),
      );
    }

    // Desktop: centered 2-column dialog
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.45),
      body: Center(
        child: Container(
          width: 860,
          height: 600,
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 48, offset: const Offset(0, 16))],
          ),
          clipBehavior: Clip.antiAlias,
          child: const _AddExpenseDesktop(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  DESKTOP — 2-column layout
// ════════════════════════════════════════════════════════════════════

class _AddExpenseDesktop extends StatefulWidget {
  const _AddExpenseDesktop();

  @override
  State<_AddExpenseDesktop> createState() => _AddExpenseDesktopState();
}

class _AddExpenseDesktopState extends State<_AddExpenseDesktop>
    with SingleTickerProviderStateMixin {

  String _raw      = '0';
  int    _catIndex = 0;
  final  _nameCtrl = TextEditingController();
  late   AnimationController _anim;
  late   Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() { _anim.dispose(); _nameCtrl.dispose(); super.dispose(); }

  void _press(String k) {
    HapticFeedback.lightImpact();
    setState(() {
      if (k == '.' && _raw.contains('.')) return;
      if (_raw == '0' && k != '.') _raw = k;
      else { if (_raw.split('.')[0].length >= 10) return; _raw += k; }
    });
    _anim.forward(from: 0);
  }

  void _delete() {
    HapticFeedback.lightImpact();
    setState(() => _raw = _raw.length > 1 ? _raw.substring(0, _raw.length - 1) : '0');
  }

  double get _amount => double.tryParse(_raw) ?? 0;

  String get _display {
    final parts = _raw.split('.');
    final fmt = (int.tryParse(parts[0]) ?? 0).toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return parts.length > 1 ? '$fmt.${parts[1]}' : fmt;
  }

  Future<void> _save() async {
    if (_amount <= 0) { _anim.forward(from: 0).then((_) => _anim.reverse()); return; }
    final cat = _cats[_catIndex];
    await StorageService.addExpense(Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim().isEmpty ? cat.label : _nameCtrl.text.trim(),
      amount: _amount, category: cat.label,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── LEFT: green panel ──────────────────────────────────────
        Container(
          width: 320,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kGreen, _kGreenDark],
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(height: 32),

              const Text('NEW EXPENSES', style: TextStyle(
                color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
              )),
              const SizedBox(height: 16),

              // Amount
              ScaleTransition(
                scale: _scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_display, style: const TextStyle(
                      color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold,
                      letterSpacing: -1, height: 1,
                    )),
                    const SizedBox(height: 6),
                    Text(
                      _amount > 0 ? 'đồng • ${_cats[_catIndex].label}' : 'Enter the amount',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Summary info box
              if (_amount > 0)
                AnimatedOpacity(
                  opacity: _amount > 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tóm tắt', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        _summaryRow(Icons.label_outline, 'Name',
                            _nameCtrl.text.trim().isEmpty ? _cats[_catIndex].label : _nameCtrl.text.trim()),
                        const SizedBox(height: 8),
                        _summaryRow(_cats[_catIndex].icon, 'Category', _cats[_catIndex].label),
                        const SizedBox(height: 8),
                        _summaryRow(Icons.attach_money, 'Amount', '${_display}vnđ'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── RIGHT: form + numpad ───────────────────────────────────
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Tên chi tiêu'),
                      const SizedBox(height: 8),
                      _desktopTextField(),
                      const SizedBox(height: 24),
                      _sectionLabel('Danh mục'),
                      const SizedBox(height: 8),
                      _desktopCatGrid(),
                    ],
                  ),
                ),
              ),

              // Numpad at bottom right
              Container(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  children: [
                    _buildNumpadDesktop(),
                    const SizedBox(height: 12),
                    _buildSaveBtn(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _sectionLabel(String t) => Text(t.toUpperCase(),
    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1));

  Widget _desktopTextField() {
    return TextField(
      controller: _nameCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Examples: Beef pho, Grab, electricity bill...',
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8F5E8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8F5E8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kGreen, width: 1.5)),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF222222), fontWeight: FontWeight.w500),
    );
  }

  Widget _desktopCatGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1,
      ),
      itemCount: _cats.length,
      itemBuilder: (_, i) {
        final cat    = _cats[i];
        final active = _catIndex == i;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _catIndex = i); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: active ? cat.color.withOpacity(0.12) : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? cat.color : Colors.transparent, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon, color: active ? cat.color : Colors.grey, size: 20),
                const SizedBox(height: 4),
                Text(cat.label, style: TextStyle(
                  fontSize: 10, color: active ? cat.color : Colors.grey,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumpadDesktop() {
    const keys = [['1','2','3'],['4','5','6'],['7','8','9'],['.','0','⌫']];
    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: row.map((k) {
            final isDel = k == '⌫';
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: k == row.first ? 0 : 3, right: k == row.last ? 0 : 3),
                child: GestureDetector(
                  onTap: isDel ? _delete : () => _press(k),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDel ? const Color(0xFFFFF5F5) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDel ? const Color(0xFFFFE0E0) : const Color(0xFFF0F0F0)),
                    ),
                    alignment: Alignment.center,
                    child: isDel
                        ? const Icon(Icons.backspace_outlined, color: Color(0xFFE85454), size: 18)
                        : Text(k, style: TextStyle(
                            fontSize: k == '.' ? 24 : 18,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF222222),
                            height: 1,
                          )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }

  Widget _buildSaveBtn() {
    final cat     = _cats[_catIndex];
    final enabled = _amount > 0;
    return GestureDetector(
      onTap: enabled ? _save : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? _kGreen : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, color: enabled ? Colors.white : Colors.grey.shade500, size: 16),
            const SizedBox(width: 8),
            Text(
              enabled ? 'Save ${cat.label.toLowerCase()} • ${_display}vnđ' : 'Enter the amount',
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey.shade500,
                fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  MOBILE + TABLET — single column content
// ════════════════════════════════════════════════════════════════════

class _AddExpenseContent extends StatefulWidget {
  const _AddExpenseContent();

  @override
  State<_AddExpenseContent> createState() => _AddExpenseContentState();
}

class _AddExpenseContentState extends State<_AddExpenseContent>
    with SingleTickerProviderStateMixin {

  String _raw      = '0';
  int    _catIndex = 0;
  final  _nameCtrl = TextEditingController();
  late   AnimationController _anim;
  late   Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() { _anim.dispose(); _nameCtrl.dispose(); super.dispose(); }

  void _press(String k) {
    HapticFeedback.lightImpact();
    setState(() {
      if (k == '.' && _raw.contains('.')) return;
      if (_raw == '0' && k != '.') _raw = k;
      else { if (_raw.split('.')[0].length >= 10) return; _raw += k; }
    });
    _anim.forward(from: 0);
  }

  void _delete() {
    HapticFeedback.lightImpact();
    setState(() => _raw = _raw.length > 1 ? _raw.substring(0, _raw.length - 1) : '0');
  }

  double get _amount => double.tryParse(_raw) ?? 0;

  String get _display {
    final parts = _raw.split('.');
    final fmt = (int.tryParse(parts[0]) ?? 0).toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return parts.length > 1 ? '$fmt.${parts[1]}' : fmt;
  }

  Future<void> _save() async {
    if (_amount <= 0) { _anim.forward(from: 0).then((_) => _anim.reverse()); return; }
    final cat = _cats[_catIndex];
    await StorageService.addExpense(Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim().isEmpty ? cat.label : _nameCtrl.text.trim(),
      amount: _amount, category: cat.label,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r         = _R.of(context);
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    // Tablet: no status bar padding (inside card)
    final effectiveTop = r.isTablet ? 0.0 : topPad;

    return Column(
      children: [
        // ── Header ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_kGreen, _kGreenDark]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          padding: EdgeInsets.fromLTRB(20, effectiveTop + 16, 20, 28),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
              const Expanded(
                child: Text('NEW EXPENSES', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
              ),
              const SizedBox(width: 36),
            ]),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _scale,
              child: Column(children: [
                Text(_display, style: TextStyle(
                  color: Colors.white, fontSize: r.isTablet ? 44 : 52,
                  fontWeight: FontWeight.bold, letterSpacing: -1, height: 1,
                )),
                const SizedBox(height: 6),
                Text(
                  _amount > 0 ? 'đồng • ${_cats[_catIndex].label}' : 'Enter the amount',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ]),
            ),
          ]),
        ),

        // ── Body ──
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              r.isTablet ? 24 : 16, 16,
              r.isTablet ? 24 : 16, bottomPad + 16,
            ),
            child: Column(children: [
              _nameField(),
              const SizedBox(height: 12),
              _catPicker(r),
              const SizedBox(height: 16),
              _numpad(r),
              const SizedBox(height: 16),
              _saveBtn(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _nameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5E8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TÊN CHI TIÊU',
          style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Examples: Beef pho, Grab, electricity bill...',
            hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 15, color: Color(0xFF222222), fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }

  Widget _catPicker(_R r) {
    // Tablet: 8 columns (all in one row), Mobile: 4 columns
    final cols = r.isTablet ? 8 : 4;
    final ratio = r.isTablet ? 0.75 : 0.9;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5E8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DANH MỤC',
          style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: ratio,
          ),
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final cat    = _cats[i];
            final active = _catIndex == i;
            return GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _catIndex = i); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: active ? cat.color.withOpacity(0.12) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? cat.color : Colors.transparent, width: 1.5),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(cat.icon, color: active ? cat.color : Colors.grey, size: 22),
                  const SizedBox(height: 4),
                  Text(cat.label, style: TextStyle(
                    fontSize: 10, color: active ? cat.color : Colors.grey,
                    fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _numpad(_R r) {
    // Tablet: numpad in 2 sections side by side
    if (r.isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _numpadGrid(keyHeight: 52)),
          const SizedBox(width: 12),
          // Quick amounts on tablet
          SizedBox(
            width: 120,
            child: Column(children: [
              const Text('NHANH', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 8),
              ...[50000, 100000, 200000, 500000].map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () { setState(() => _raw = v.toString()); _anim.forward(from: 0); },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGreen.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      v >= 1000000 ? '${v ~/ 1000000}M' : '${v ~/ 1000}K',
                      style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              )),
            ]),
          ),
        ],
      );
    }
    return _numpadGrid(keyHeight: 56);
  }

  Widget _numpadGrid({required double keyHeight}) {
    const keys = [['1','2','3'],['4','5','6'],['7','8','9'],['.','0','⌫']];
    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: row.map((k) {
            final isDel = k == '⌫';
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: k == row.first ? 0 : 4, right: k == row.last ? 0 : 4),
                child: GestureDetector(
                  onTap: isDel ? _delete : () => _press(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: keyHeight,
                    decoration: BoxDecoration(
                      color: isDel ? const Color(0xFFFFF5F5) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDel ? const Color(0xFFFFE0E0) : const Color(0xFFF0F0F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    alignment: Alignment.center,
                    child: isDel
                        ? const Icon(Icons.backspace_outlined, color: Color(0xFFE85454), size: 20)
                        : Text(k, style: TextStyle(
                            fontSize: k == '.' ? 28 : 22,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF222222), height: 1,
                          )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }

  Widget _saveBtn() {
    final cat     = _cats[_catIndex];
    final enabled = _amount > 0;
    return GestureDetector(
      onTap: enabled ? _save : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? _kGreen : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(cat.icon, color: enabled ? Colors.white : Colors.grey.shade500, size: 18),
          const SizedBox(width: 8),
          Text(
            enabled ? 'Save ${cat.label.toLowerCase()} • ${_display}vnđ' : 'Enter the amount',
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey.shade500,
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3,
            ),
          ),
        ]),
      ),
    );
  }
}