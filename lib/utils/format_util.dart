import 'package:intl/intl.dart';

class FormatUtil {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String rupiah(num value) => _rupiah.format(value);

  static String rupiahShort(num value) {
    if (value >= 1000000) {
      final m = value / 1000000;
      return 'Rp ${_trim(m)}jt';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return 'Rp ${_trim(k)}k';
    }
    return _rupiah.format(value);
  }

  static String _trim(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  static String number(num value) => NumberFormat.decimalPattern('id_ID').format(value);

  static String date(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

  static String dateShort(DateTime d) => DateFormat('d MMM', 'id_ID').format(d);

  static String time(DateTime d) => DateFormat.Hm('id_ID').format(d);

  static String dateTime(DateTime d) => DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);

  static String monthYear(DateTime d) => DateFormat('MMMM yyyy', 'id_ID').format(d);

  static String dayName(DateTime d) => DateFormat('EEEE', 'id_ID').format(d);

  static String dateLong(DateTime d) => DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);

  static String dayShort(DateTime d) => DateFormat('d MMM', 'id_ID').format(d);

  static String longDate(DateTime d) => DateFormat('d MMMM yyyy', 'id_ID').format(d);

  static String invoice(DateTime d, int seq) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final s = (seq).toString().padLeft(3, '0');
    return 'INV/$y$m$day/$s';
  }
}
