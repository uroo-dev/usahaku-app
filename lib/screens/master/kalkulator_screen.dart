import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Kalkulator inline — tanpa riwayat, tampilkan ekspresi aktif saat memilih operator.
class KalkulatorScreen extends StatefulWidget {
  const KalkulatorScreen({super.key});

  @override
  State<KalkulatorScreen> createState() => _KalkulatorScreenState();
}

class _KalkulatorScreenState extends State<KalkulatorScreen> {
  String _display = '0';   // angka yang sedang diketik
  String _expression = ''; // ekspresi lengkap misal "1.500 +"
  double? _left;
  String? _op;
  bool _fresh = true;      // reset angka berikutnya setelah operator / hasil

  void _tap(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _display = '0';
          _expression = '';
          _left = null;
          _op = null;
          _fresh = true;

        case '⌫':
          if (_fresh) return;
          _display = _display.length > 1
              ? _display.substring(0, _display.length - 1)
              : '0';
          if (_display == '-') _display = '0';

        case '+':
        case '-':
        case '×':
        case '÷':
          _left = double.tryParse(_display) ?? 0;
          _op = key;
          _expression = '${_formatNum(_left!)} $key';
          _fresh = true;

        case '=':
          final right = double.tryParse(_display) ?? 0;
          if (_left != null && _op != null) {
            final result = _compute(_left!, _op!, right);
            _expression = '${_formatNum(_left!)} $_op ${_formatNum(right)} =';
            _display = _formatNum(result);
            _left = result;
            _op = null;
          }
          _fresh = true;

        case '%':
          final val = double.tryParse(_display) ?? 0;
          final pct = val / 100;
          _display = _formatNum(pct);

        default:
          if (_fresh) {
            _display = key == '.' ? '0.' : key;
            _fresh = false;
          } else if (_display == '0' && key != '.') {
            _display = key;
          } else if (key == '.' && _display.contains('.')) {
            // sudah ada titik, abaikan
          } else {
            _display += key;
          }
      }
    });
  }

  double _compute(double a, String op, double b) {
    return switch (op) {
      '+' => a + b,
      '-' => a - b,
      '×' => a * b,
      '÷' => b == 0 ? double.nan : a / b,
      _ => b,
    };
  }

  String _formatNum(double v) {
    if (v.isNaN) return 'Error';
    if (v.isInfinite) return v > 0 ? 'Inf' : '-Inf';
    if (v == v.roundToDouble() && v.abs() < 1e12) return v.toInt().toString();
    // max 8 desimal, tanpa trailing zero
    return v.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    // Layout tombol: baris pertama C + ⌫ + % + ÷, lalu 3x3 angka dengan operator
    const rows = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Display area ──
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Ekspresi (misal "1500 +" atau "1500 × 2 =")
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        _expression,
                        key: ValueKey(_expression),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColor.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Angka utama
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: _display == 'Error'
                              ? AppColor.error
                              : AppColor.onSurface,
                          letterSpacing: -1,
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
                                isActiveOp: key == _op,
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
    if (key == '+' || key == '-' || key == '×' || key == '÷') return _ButtonType.operator;
    return _ButtonType.number;
  }
}

enum _ButtonType { number, operator, equals, clear, function }

class _CalcButton extends StatelessWidget {
  final String label;
  final _ButtonType type;
  final VoidCallback onTap;
  final bool isActiveOp; // highlight operator yang sedang aktif

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
          [BoxShadow(color: AppColor.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
      _ButtonType.clear => (
          AppColor.error,
          Colors.white,
          16.0,
          <BoxShadow>[BoxShadow(color: AppColor.error.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
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

    // Tampilkan ikon untuk backspace, label "C" untuk clear
    Widget child;
    if (label == '⌫') {
      child = Icon(Icons.backspace_outlined, color: fg, size: 22);
    } else if (label == 'C') {
      child = Text(
        'C',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg),
      );
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
