import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Kalkulator dengan expression parser lengkap.
/// Mendukung ekspresi panjang: 100+1-3×4÷2 dengan operator precedence yang benar.
class KalkulatorScreen extends StatefulWidget {
  const KalkulatorScreen({super.key});

  @override
  State<KalkulatorScreen> createState() => _KalkulatorScreenState();
}

class _KalkulatorScreenState extends State<KalkulatorScreen> {
  /// Ekspresi yang ditampilkan dan diedit user (misal "100+1-3×4")
  String _expr = '';

  /// Hasil / angka yang sedang aktif di display bawah
  String _display = '0';

  /// True jika baru saja menekan "=" — ketukan angka berikutnya reset ekspresi
  bool _justEvaled = false;

  // ─── Input handling ──────────────────────────────────────────────

  void _tap(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expr = '';
          _display = '0';
          _justEvaled = false;

        case '⌫':
          if (_justEvaled) {
            _expr = '';
            _display = '0';
            _justEvaled = false;
            return;
          }
          if (_expr.isNotEmpty) {
            _expr = _expr.substring(0, _expr.length - 1);
          }
          _display = _currentToken(_expr);

        case '+':
        case '-':
        case '×':
        case '÷':
          _justEvaled = false;
          if (_expr.isEmpty) {
            // mulai dengan operator: asumsikan 0
            _expr = '0$key';
          } else {
            final last = _expr[_expr.length - 1];
            if (_isOperator(last)) {
              // ganti operator terakhir
              _expr = _expr.substring(0, _expr.length - 1) + key;
            } else {
              _expr += key;
            }
          }
          _display = _currentToken(_expr);

        case '%':
          // Konversi angka terakhir ke persen
          if (_expr.isEmpty) {
            final val = double.tryParse(_display) ?? 0;
            _display = _fmt(val / 100);
            _expr = _display;
          } else {
            final last = _expr[_expr.length - 1];
            if (!_isOperator(last)) {
              final token = _currentToken(_expr);
              final val = double.tryParse(token) ?? 0;
              final pct = _fmt(val / 100);
              _expr = _expr.substring(0, _expr.length - token.length) + pct;
              _display = pct;
            }
          }

        case '=':
          if (_expr.isEmpty) return;
          final last = _expr[_expr.length - 1];
          // Buang trailing operator sebelum evaluate
          final exprToEval = _isOperator(last)
              ? _expr.substring(0, _expr.length - 1)
              : _expr;
          if (exprToEval.isEmpty) return;
          try {
            final result = _evaluate(exprToEval);
            _display = _fmt(result);
            // Tampilkan ekspresi lengkap di baris atas, lalu set display ke hasil
            _expr = '$exprToEval=';
            _justEvaled = true;
          } catch (_) {
            _display = 'Error';
            _expr = '';
            _justEvaled = true;
          }

        default:
          // Digit atau titik desimal
          if (_justEvaled) {
            // Mulai ekspresi baru setelah hasil
            _expr = '';
            _justEvaled = false;
          }
          if (_expr.isNotEmpty && _expr[_expr.length - 1] == '=') {
            _expr = '';
          }
          // Hindari titik ganda dalam token yang sama
          if (key == '.') {
            final token = _currentToken(_expr);
            if (token.contains('.')) return;
          }
          // Hindari leading zero (0123 → 123)
          if (key != '.') {
            final token = _currentToken(_expr);
            if (token == '0') {
              _expr = _expr.isEmpty ? key : _expr.substring(0, _expr.length - 1) + key;
              _display = _currentToken(_expr);
              return;
            }
          }
          _expr += key;
          _display = _currentToken(_expr);
      }
    });
  }

  // ─── Expression parser (Shunting-Yard → RPN → evaluate) ──────────

  /// Ambil token angka terakhir dari ekspresi (untuk display utama)
  String _currentToken(String expr) {
    if (expr.isEmpty) return '0';
    if (expr.endsWith('=')) return _display;
    final parts = expr.split(RegExp(r'(?<=[^eE])[+\-×÷]'));
    final last = parts.last;
    return last.isEmpty ? '0' : last;
  }

  bool _isOperator(String c) => c == '+' || c == '-' || c == '×' || c == '÷';

  int _precedence(String op) {
    if (op == '+' || op == '-') return 1;
    if (op == '×' || op == '÷') return 2;
    return 0;
  }

  /// Evaluate ekspresi string (tanpa tanda sama dengan) — Shunting-Yard
  double _evaluate(String expr) {
    final tokens = _tokenize(expr);
    // Shunting-Yard → output queue (RPN)
    final output = <double>[];
    final ops = <String>[];

    void applyOp() {
      if (output.length < 2 || ops.isEmpty) return;
      final b = output.removeLast();
      final a = output.removeLast();
      final op = ops.removeLast();
      output.add(_applyOp(a, op, b));
    }

    for (final tok in tokens) {
      final num = double.tryParse(tok);
      if (num != null) {
        output.add(num);
      } else if (_isOperator(tok)) {
        while (ops.isNotEmpty &&
            _isOperator(ops.last) &&
            _precedence(ops.last) >= _precedence(tok)) {
          applyOp();
        }
        ops.add(tok);
      }
    }
    while (ops.isNotEmpty) {
      applyOp();
    }
    if (output.isEmpty) throw Exception('Invalid expression');
    return output.last;
  }

  /// Tokenize ekspresi: pisahkan angka dan operator
  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    var buf = StringBuffer();
    for (int i = 0; i < expr.length; i++) {
      final c = expr[i];
      if (_isOperator(c)) {
        // Tanda minus sebagai unary (di awal atau setelah operator)
        if (c == '-' && (i == 0 || _isOperator(expr[i - 1]))) {
          buf.write(c);
        } else {
          if (buf.isNotEmpty) {
            tokens.add(buf.toString());
            buf.clear();
          }
          tokens.add(c);
        }
      } else {
        buf.write(c);
      }
    }
    if (buf.isNotEmpty) tokens.add(buf.toString());
    return tokens;
  }

  double _applyOp(double a, String op, double b) {
    return switch (op) {
      '+' => a + b,
      '-' => a - b,
      '×' => a * b,
      '÷' => b == 0 ? double.nan : a / b,
      _ => b,
    };
  }

  /// Format angka: tanpa desimal jika bulat, max 10 digit signifikan
  String _fmt(double v) {
    if (v.isNaN) return 'Error';
    if (v.isInfinite) return v > 0 ? 'Inf' : '-Inf';
    if (v == v.roundToDouble() && v.abs() < 1e12) return v.toInt().toString();
    return double.parse(v.toStringAsPrecision(10)).toString();
  }

  // ─── Operator aktif (untuk highlight tombol) ──────────────────────
  String? get _activeOp {
    if (_expr.isEmpty || _justEvaled) return null;
    final last = _expr[_expr.length - 1];
    return _isOperator(last) ? last : null;
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    // Ekspresi yang ditampilkan di baris atas (bersihkan trailing "=")
    final exprDisplay = _expr.endsWith('=')
        ? _expr // tampilkan misal "100+1-3×4="
        : _expr;

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
                          color: AppColor.onSurfaceVariant.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Angka / hasil utama
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: _display == 'Error'
                              ? AppColor.error
                              : _justEvaled
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
                                isActiveOp: key == _activeOp,
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
    if (_isOperator(key)) return _ButtonType.operator;
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
