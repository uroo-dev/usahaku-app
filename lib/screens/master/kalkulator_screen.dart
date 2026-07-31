import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/calculator_logic.dart';

/// Kalkulator dengan expression parser lengkap.
/// Mendukung ekspresi panjang: 100+1-3×4÷2 dengan operator precedence yang benar.
class KalkulatorScreen extends StatefulWidget {
  const KalkulatorScreen({super.key});

  @override
  State<KalkulatorScreen> createState() => _KalkulatorScreenState();
}

class _KalkulatorScreenState extends State<KalkulatorScreen> {
  final _calc = CalculatorLogic();

  void _tap(String key) {
    setState(() {
      _calc.tap(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    final exprDisplay = _calc.expr;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Display ──
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColor.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Ekspresi lengkap — scrollable horizontal
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        exprDisplay.isEmpty ? ' ' : exprDisplay,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColor.onSurfaceVariant
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Angka / hasil utama
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _calc.display,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: _calc.display == 'Error'
                              ? AppColor.error
                              : _calc.justEvaled
                                  ? AppColor.primary
                                  : AppColor.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tombol ──
            Expanded(
              flex: 5,
              child: Container(
                color: AppColor.surface,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: rows.map((row) {
                    return Expanded(
                      child: Row(
                        children: row.map((key) {
                          return Expanded(
                            flex: key == '0' ? 2 : 1,
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: _CalcButton(
                                label: key,
                                type: _typeOf(key),
                                onTap: () => _tap(key),
                                isActiveOp: key == _calc.activeOp,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ButtonType _typeOf(String key) {
    if (key == 'C') return _ButtonType.clear;
    if (key == '=') return _ButtonType.equals;
    if (key == '⌫' || key == '%') return _ButtonType.function;
    if (_calc.isOperator(key)) return _ButtonType.operator;
    return _ButtonType.number;
  }
}

// ─── Enum & Button widget ────────────────────────────────────────────

enum _ButtonType { number, operator, equals, clear, function }

class _CalcButton extends StatelessWidget {
  final String label;
  final _ButtonType type;
  final VoidCallback onTap;
  final bool isActiveOp;

  const _CalcButton({
    required this.label,
    required this.type,
    required this.onTap,
    this.isActiveOp = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, radius, shadow) = switch (type) {
      _ButtonType.equals => (
          AppColor.primary,
          Colors.white,
          20.0,
          [
            BoxShadow(
              color: AppColor.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      _ButtonType.clear => (
          AppColor.error,
          Colors.white,
          16.0,
          <BoxShadow>[
            BoxShadow(
              color: AppColor.error.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      _ButtonType.operator => (
          isActiveOp ? AppColor.primary : AppColor.primaryContainer,
          isActiveOp ? Colors.white : AppColor.primary,
          16.0,
          <BoxShadow>[],
        ),
      _ButtonType.function => (
          AppColor.surfaceContainerHigh,
          AppColor.onSurfaceVariant,
          16.0,
          <BoxShadow>[],
        ),
      _ButtonType.number => (
          AppColor.surfaceContainerLowest,
          AppColor.onSurface,
          16.0,
          <BoxShadow>[],
        ),
    };

    Widget child;
    if (label == '⌫') {
      child = Icon(Icons.backspace_outlined, color: fg, size: 22);
    } else {
      child = Text(
        label,
        style: TextStyle(
          fontSize: type == _ButtonType.equals ? 26 : 22,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadow,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
