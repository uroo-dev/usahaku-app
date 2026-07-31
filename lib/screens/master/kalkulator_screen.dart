import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Kalkulator sederhana — sesuai menu KEUANGAN di Lainnya.
class KalkulatorScreen extends StatefulWidget {
  const KalkulatorScreen({super.key});

  @override
  State<KalkulatorScreen> createState() => _KalkulatorScreenState();
}

class _KalkulatorScreenState extends State<KalkulatorScreen> {
  String _display = '0';
  double? _left;
  String? _op;
  bool _fresh = true;

  void _tap(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _left = null;
        _op = null;
        _fresh = true;
      } else if (key == '⌫') {
        if (_fresh) return;
        _display = _display.length > 1 ? _display.substring(0, _display.length - 1) : '0';
      } else if (key == '+' || key == '-' || key == '×' || key == '÷') {
        _op = key;
        _left = double.tryParse(_display) ?? 0;
        _fresh = true;
      } else if (key == '=') {
        final right = double.tryParse(_display) ?? 0;
        if (_left != null && _op != null) {
          final result = _compute(_left!, _op!, right);
          _display = _format(result);
          _left = result;
        }
        _fresh = true;
      } else {
        if (_fresh) {
          _display = key;
          _fresh = false;
        } else if (_display == '0' && key != '.') {
          _display = key;
        } else {
          _display += key;
        }
      }
    });
  }

  double _compute(double a, String op, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? double.nan : a / b;
    }
    return b;
  }

  String _format(double v) {
    if (v.isNaN) return 'Error';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['C', '⌫', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                color: AppColor.surfaceContainerLowest,
                child: Text(
                  _display,
                  style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: AppColor.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final row in rows) ...[
                    Row(
                      children: row.map((key) {
                        final isOp = key == '+' || key == '-' || key == '×' || key == '÷' || key == '=';
                        final isDanger = key == 'C';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _key(key,
                                color: isOp
                                    ? AppColor.primary
                                    : isDanger
                                        ? AppColor.error
                                        : AppColor.surfaceContainerHigh,
                                textColor: isOp
                                    ? Colors.white
                                    : isDanger
                                        ? AppColor.error
                                        : AppColor.onSurface),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _key(String label, {required Color color, required Color textColor}) {
    return InkWell(
      onTap: () => _tap(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
        ),
      ),
    );
  }
}
