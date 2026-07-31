import 'package:flutter_test/flutter_test.dart';
import 'package:usahaku/utils/calculator_logic.dart';

// Helper: tap sequence dari string, misal "1 2 + 3 ="
// Spasi dipakai sebagai separator antar key.
CalculatorLogic tapSeq(List<String> keys) {
  final c = CalculatorLogic();
  for (final k in keys) {
    c.tap(k);
  }
  return c;
}

void main() {
  // ─────────────────────────────────────────────
  // 1. Operasi Dasar
  // ─────────────────────────────────────────────
  group('Operasi dasar', () {
    test('penjumlahan: 7 + 3 = 10', () {
      final c = tapSeq(['7', '+', '3', '=']);
      expect(c.display, '10');
    });

    test('pengurangan: 9 - 4 = 5', () {
      final c = tapSeq(['9', '-', '4', '=']);
      expect(c.display, '5');
    });

    test('perkalian: 6 × 7 = 42', () {
      final c = tapSeq(['6', '×', '7', '=']);
      expect(c.display, '42');
    });

    test('pembagian: 8 ÷ 4 = 2', () {
      final c = tapSeq(['8', '÷', '4', '=']);
      expect(c.display, '2');
    });

    test('angka float: 1.5 + 2.5 = 4', () {
      final c = tapSeq(['1', '.', '5', '+', '2', '.', '5', '=']);
      expect(c.display, '4');
    });
  });

  // ─────────────────────────────────────────────
  // 2. Operator Precedence
  // ─────────────────────────────────────────────
  group('Operator precedence', () {
    test('2 + 3 × 4 = 14 (bukan 20)', () {
      final c = tapSeq(['2', '+', '3', '×', '4', '=']);
      expect(c.display, '14');
    });

    test('10 - 2 × 3 = 4', () {
      final c = tapSeq(['1', '0', '-', '2', '×', '3', '=']);
      expect(c.display, '4');
    });

    test('8 ÷ 4 + 2 = 4', () {
      final c = tapSeq(['8', '÷', '4', '+', '2', '=']);
      expect(c.display, '4');
    });

    test('100 + 1 - 3 × 4 ÷ 2 = 95', () {
      // 100 + 1 - (3×4÷2) = 100 + 1 - 6 = 95
      final c = tapSeq(['1', '0', '0', '+', '1', '-', '3', '×', '4', '÷', '2', '=']);
      expect(c.display, '95');
    });
  });

  // ─────────────────────────────────────────────
  // 3. Unary Minus
  // ─────────────────────────────────────────────
  group('Unary minus (angka negatif)', () {
    test('evaluate("-5") = -5', () {
      final c = CalculatorLogic();
      expect(c.evaluate('-5'), -5);
    });

    test('evaluate("-3 + 8") = 5', () {
      final c = CalculatorLogic();
      expect(c.evaluate('-3+8'), 5);
    });

    test('evaluate("-2 × -3") = 6', () {
      final c = CalculatorLogic();
      expect(c.evaluate('-2×-3'), 6);
    });
  });

  // ─────────────────────────────────────────────
  // 4. Persen (%)
  // ─────────────────────────────────────────────
  group('Tombol persen', () {
    test('50 % = 0.5', () {
      final c = tapSeq(['5', '0', '%']);
      expect(c.display, '0.5');
    });

    test('200 % = 2', () {
      final c = tapSeq(['2', '0', '0', '%']);
      expect(c.display, '2');
    });

    test('% pada token terakhir dalam ekspresi: 100 + 50 % → 100 + 0.5', () {
      // Tap 100+50%, lalu =
      final c = tapSeq(['1', '0', '0', '+', '5', '0', '%', '=']);
      expect(c.display, '100.5');
    });
  });

  // ─────────────────────────────────────────────
  // 5. Backspace (⌫)
  // ─────────────────────────────────────────────
  group('Tombol backspace', () {
    test('hapus digit terakhir: 123 ⌫ → 12', () {
      final c = tapSeq(['1', '2', '3', '⌫']);
      expect(c.display, '12');
      expect(c.expr, '12');
    });

    test('hapus operator: 5+ ⌫ → 5', () {
      final c = tapSeq(['5', '+', '⌫']);
      // setelah hapus '+', token terakhir = 5
      expect(c.expr, '5');
    });

    test('⌫ setelah eval reset ke 0', () {
      final c = tapSeq(['5', '+', '3', '=', '⌫']);
      expect(c.display, '0');
      expect(c.expr, '');
      expect(c.justEvaled, false);
    });

    test('⌫ pada ekspresi kosong tidak error', () {
      final c = CalculatorLogic();
      c.tap('⌫');
      expect(c.display, '0');
      expect(c.expr, '');
    });
  });

  // ─────────────────────────────────────────────
  // 6. Clear (C)
  // ─────────────────────────────────────────────
  group('Tombol C (clear)', () {
    test('clear setelah input panjang', () {
      final c = tapSeq(['9', '9', '+', '1', 'C']);
      expect(c.display, '0');
      expect(c.expr, '');
      expect(c.justEvaled, false);
    });

    test('clear setelah eval', () {
      final c = tapSeq(['5', '×', '5', '=', 'C']);
      expect(c.display, '0');
      expect(c.justEvaled, false);
    });
  });

  // ─────────────────────────────────────────────
  // 7. Edge Cases — Input tombol
  // ─────────────────────────────────────────────
  group('Edge cases — input tombol', () {
    test('titik ganda tidak bisa diinput: 1.2. → 1.2', () {
      final c = tapSeq(['1', '.', '2', '.']);
      expect(c.display, '1.2');
    });

    test('leading zero diganti: 0 lalu 5 → 5', () {
      final c = tapSeq(['0', '5']);
      expect(c.display, '5');
    });

    test('ganti operator terakhir: 5 + × → 5×', () {
      final c = tapSeq(['5', '+', '×']);
      expect(c.expr, '5×');
      expect(c.activeOp, '×');
    });

    test('operator di awal: + dipakai → 0+', () {
      final c = tapSeq(['+']);
      expect(c.expr, '0+');
    });

    test('= pada ekspresi kosong tidak crash', () {
      final c = CalculatorLogic();
      c.tap('=');
      expect(c.display, '0');
    });

    test('= trailing operator dihapus sebelum eval: 5+ = 5', () {
      final c = tapSeq(['5', '+', '=']);
      expect(c.display, '5');
    });

    test('ketik angka setelah eval memulai ekspresi baru', () {
      final c = tapSeq(['4', '+', '4', '=', '9']);
      expect(c.expr, '9');
      expect(c.display, '9');
      expect(c.justEvaled, false);
    });
  });

  // ─────────────────────────────────────────────
  // 8. Divide by zero
  // ─────────────────────────────────────────────
  group('Bagi dengan nol', () {
    test('5 ÷ 0 = Error', () {
      final c = tapSeq(['5', '÷', '0', '=']);
      expect(c.display, 'Error');
    });
  });

  // ─────────────────────────────────────────────
  // 9. Chained operations (tanpa = di tengah)
  // ─────────────────────────────────────────────
  group('Chained ops tanpa = di tengah', () {
    test('1+2+3+4 = 10', () {
      final c = tapSeq(['1', '+', '2', '+', '3', '+', '4', '=']);
      expect(c.display, '10');
    });

    test('100 ÷ 5 ÷ 2 = 10', () {
      final c = tapSeq(['1', '0', '0', '÷', '5', '÷', '2', '=']);
      expect(c.display, '10');
    });
  });

  // ─────────────────────────────────────────────
  // 10. Tokenizer
  // ─────────────────────────────────────────────
  group('Tokenizer', () {
    late CalculatorLogic c;
    setUp(() => c = CalculatorLogic());

    test('tokenize "3+4" → [3, +, 4]', () {
      expect(c.tokenize('3+4'), ['3', '+', '4']);
    });

    test('tokenize "3.14×2" → [3.14, ×, 2]', () {
      expect(c.tokenize('3.14×2'), ['3.14', '×', '2']);
    });

    test('tokenize "-5+3" → [-5, +, 3]', () {
      expect(c.tokenize('-5+3'), ['-5', '+', '3']);
    });

    test('tokenize "2×-3" → [2, ×, -3]', () {
      expect(c.tokenize('2×-3'), ['2', '×', '-3']);
    });

    test('tokenize "" → []', () {
      expect(c.tokenize(''), []);
    });
  });

  // ─────────────────────────────────────────────
  // 11. Formatter (fmt)
  // ─────────────────────────────────────────────
  group('Formatter fmt()', () {
    late CalculatorLogic c;
    setUp(() => c = CalculatorLogic());

    test('bilangan bulat: 5.0 → "5"', () {
      expect(c.fmt(5.0), '5');
    });

    test('bilangan bulat negatif: -3.0 → "-3"', () {
      expect(c.fmt(-3.0), '-3');
    });

    test('desimal: 3.14 → "3.14"', () {
      expect(c.fmt(3.14), '3.14');
    });

    test('NaN → "Error"', () {
      expect(c.fmt(double.nan), 'Error');
    });

    test('Infinity → "Inf"', () {
      expect(c.fmt(double.infinity), 'Inf');
    });

    test('Negative Infinity → "-Inf"', () {
      expect(c.fmt(double.negativeInfinity), '-Inf');
    });

    test('zero → "0"', () {
      expect(c.fmt(0), '0');
    });
  });

  // ─────────────────────────────────────────────
  // 12. activeOp getter
  // ─────────────────────────────────────────────
  group('activeOp', () {
    test('null saat expr kosong', () {
      expect(CalculatorLogic().activeOp, isNull);
    });

    test('null setelah eval', () {
      final c = tapSeq(['3', '+', '3', '=']);
      expect(c.activeOp, isNull);
    });

    test('mengembalikan operator terakhir', () {
      final c = tapSeq(['5', '×']);
      expect(c.activeOp, '×');
    });

    test('null saat token angka terakhir', () {
      final c = tapSeq(['5', '×', '3']);
      expect(c.activeOp, isNull);
    });
  });

  // ─────────────────────────────────────────────
  // 13. reset()
  // ─────────────────────────────────────────────
  group('reset()', () {
    test('reset setelah banyak input', () {
      final c = tapSeq(['9', '9', '×', '9', '9', '=']);
      c.reset();
      expect(c.expr, '');
      expect(c.display, '0');
      expect(c.justEvaled, false);
    });
  });

  // ─────────────────────────────────────────────
  // 14. Angka besar & presisi
  // ─────────────────────────────────────────────
  group('Angka besar dan presisi', () {
    test('999999999 + 1 = 1000000000', () {
      final c = CalculatorLogic();
      expect(c.evaluate('999999999+1'), 1000000000);
    });

    test('1 ÷ 3 tidak crash (desimal panjang)', () {
      final c = tapSeq(['1', '÷', '3', '=']);
      expect(c.display, isNot('Error'));
      expect(c.display.contains('.'), isTrue);
    });
  });
}
