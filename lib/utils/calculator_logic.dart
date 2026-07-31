/// Logika kalkulator murni — bebas dari Flutter/Widget.
///
/// Bisa diuji dengan unit test biasa tanpa memerlukan `flutter_test`.
/// Mendukung ekspresi panjang: 100+1-3×4÷2 dengan operator precedence.
class CalculatorLogic {
  /// Ekspresi yang sedang dibangun (misal "100+1-3×4")
  String expr = '';

  /// Angka / hasil yang ditampilkan di display utama
  String display = '0';

  /// True setelah "=" ditekan — ketukan digit berikutnya reset ekspresi
  bool justEvaled = false;

  // ─── Tap handler utama ─────────────────────────────────────────

  /// Proses ketukan tombol. Kembalikan state yang sudah diperbarui (mutates
  /// [expr], [display], [justEvaled] in-place; juga return [this] untuk chaining).
  CalculatorLogic tap(String key) {
    switch (key) {
      case 'C':
        expr = '';
        display = '0';
        justEvaled = false;

      case '⌫':
        if (justEvaled) {
          expr = '';
          display = '0';
          justEvaled = false;
          break;
        }
        if (expr.isNotEmpty) {
          expr = expr.substring(0, expr.length - 1);
        }
        display = currentToken(expr);

      case '+':
      case '-':
      case '×':
      case '÷':
        justEvaled = false;
        if (expr.isEmpty) {
          expr = '0$key';
        } else {
          final last = expr[expr.length - 1];
          if (isOperator(last)) {
            expr = expr.substring(0, expr.length - 1) + key;
          } else {
            expr += key;
          }
        }
        display = currentToken(expr);

      case '%':
        if (expr.isEmpty) {
          final val = double.tryParse(display) ?? 0;
          display = fmt(val / 100);
          expr = display;
        } else {
          final last = expr[expr.length - 1];
          if (!isOperator(last)) {
            final token = currentToken(expr);
            final val = double.tryParse(token) ?? 0;
            final pct = fmt(val / 100);
            expr = expr.substring(0, expr.length - token.length) + pct;
            display = pct;
          }
        }

      case '=':
        if (expr.isEmpty) break;
        final last = expr[expr.length - 1];
        final exprToEval =
            isOperator(last) ? expr.substring(0, expr.length - 1) : expr;
        if (exprToEval.isEmpty) break;
        try {
          final result = evaluate(exprToEval);
          display = fmt(result);
          expr = '$exprToEval=';
          justEvaled = true;
        } catch (_) {
          display = 'Error';
          expr = '';
          justEvaled = true;
        }

      default:
        // Digit atau titik desimal
        if (justEvaled) {
          expr = '';
          justEvaled = false;
        }
        if (expr.isNotEmpty && expr[expr.length - 1] == '=') {
          expr = '';
        }
        // Hindari titik ganda dalam token yang sama
        if (key == '.') {
          final token = currentToken(expr);
          if (token.contains('.')) break;
        }
        // Hindari leading zero: 0 → ganti langsung (bukan 01, 02, ...)
        // Hanya berlaku jika token terakhir benar-benar '0' yang diketik user
        // (bukan '0' palsu dari token kosong setelah operator).
        if (key != '.') {
          final lastCharIsOp =
              expr.isNotEmpty && isOperator(expr[expr.length - 1]);
          final token = currentToken(expr);
          if (token == '0' && !lastCharIsOp && expr.isNotEmpty) {
            expr = expr.substring(0, expr.length - 1) + key;
            display = currentToken(expr);
            break;
          } else if (token == '0' && expr.isEmpty) {
            expr = key;
            display = currentToken(expr);
            break;
          }
        }
        expr += key;
        display = currentToken(expr);
    }
    return this;
  }

  // ─── Helpers public (diperlukan agar bisa diuji) ───────────────

  /// Ambil token angka terakhir dari ekspresi (untuk display utama).
  String currentToken(String e) {
    if (e.isEmpty) return '0';
    if (e.endsWith('=')) return display;
    final parts = e.split(RegExp(r'(?<=[^eE])[+\-×÷]'));
    final last = parts.last;
    return last.isEmpty ? '0' : last;
  }

  bool isOperator(String c) =>
      c == '+' || c == '-' || c == '×' || c == '÷';

  int precedence(String op) {
    if (op == '+' || op == '-') return 1;
    if (op == '×' || op == '÷') return 2;
    return 0;
  }

  /// Evaluate ekspresi string (tanpa "=") menggunakan Shunting-Yard.
  double evaluate(String e) {
    final tokens = tokenize(e);
    final output = <double>[];
    final ops = <String>[];

    void applyOp() {
      if (output.length < 2 || ops.isEmpty) return;
      final b = output.removeLast();
      final a = output.removeLast();
      final op = ops.removeLast();
      output.add(applyOpPair(a, op, b));
    }

    for (final tok in tokens) {
      final num = double.tryParse(tok);
      if (num != null) {
        output.add(num);
      } else if (isOperator(tok)) {
        while (ops.isNotEmpty &&
            isOperator(ops.last) &&
            precedence(ops.last) >= precedence(tok)) {
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

  /// Tokenize ekspresi: pisahkan angka desimal dan operator.
  List<String> tokenize(String e) {
    final tokens = <String>[];
    var buf = StringBuffer();
    for (int i = 0; i < e.length; i++) {
      final c = e[i];
      if (isOperator(c)) {
        // Tanda minus unary: di awal atau langsung setelah operator
        if (c == '-' && (i == 0 || isOperator(e[i - 1]))) {
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

  double applyOpPair(double a, String op, double b) {
    return switch (op) {
      '+' => a + b,
      '-' => a - b,
      '×' => a * b,
      '÷' => b == 0 ? double.nan : a / b,
      _ => b,
    };
  }

  /// Format angka: integer jika bulat, max 10 digit signifikan.
  String fmt(double v) {
    if (v.isNaN) return 'Error';
    if (v.isInfinite) return v > 0 ? 'Inf' : '-Inf';
    if (v == v.roundToDouble() && v.abs() < 1e12) return v.toInt().toString();
    return double.parse(v.toStringAsPrecision(10)).toString();
  }

  /// Operator aktif saat ini (untuk highlight tombol di UI).
  String? get activeOp {
    if (expr.isEmpty || justEvaled) return null;
    final last = expr[expr.length - 1];
    return isOperator(last) ? last : null;
  }

  /// Reset penuh ke state awal.
  void reset() {
    expr = '';
    display = '0';
    justEvaled = false;
  }
}
