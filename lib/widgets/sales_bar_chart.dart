import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Grafik batang pendapatan 7 hari terakhir, digambar manual tanpa library.
class SalesBarChart extends StatelessWidget {
  final List<double> values; // index 0 = hari tertua
  final List<DateTime> dates;

  const SalesBarChart({super.key, required this.values, required this.dates});

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v > 0);
    final maxValue = values.fold<double>(0, (m, v) => v > m ? v : m);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasData)
            _ValueHeader(values: values, dates: dates)
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Total minggu ini: Rp 0',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.onSurface,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarPainter(
                values: values,
                dates: dates,
                maxValue: maxValue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dates.map((d) {
              final today = DateTime.now();
              final isToday = d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day;
              final label = isToday
                  ? 'Hari Ini'
                  : FormatUtil.dayName(d).substring(0, 3);
              return Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? AppColor.primary
                        : AppColor.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ValueHeader extends StatelessWidget {
  final List<double> values;
  final List<DateTime> dates;

  const _ValueHeader({required this.values, required this.dates});

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final bestIndex = values.indexOf(values.reduce((a, b) => a > b ? a : b));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total minggu ini: ${FormatUtil.rupiah(total)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColor.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tertinggi ${FormatUtil.dayName(dates[bestIndex])} · ${FormatUtil.rupiahShort(values[bestIndex])}',
          style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final List<DateTime> dates;
  final double maxValue;

  _BarPainter({
    required this.values,
    required this.dates,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 16;
    final topPad = 12.0;
    final effectiveHeight = chartHeight - topPad;
    final slot = size.width / values.length;
    final barWidth = slot * 0.45;

    // Garis dasar
    final baseline = Offset(0, size.height - 4);
    final gridPaint = Paint()
      ..color = AppColor.outlineVariant.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = baseline.dy - (effectiveHeight * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final x = i * slot + (slot - barWidth) / 2;
      final ratio = maxValue == 0 ? 0.0 : (v / maxValue).clamp(0.0, 1.0);
      final barH = effectiveHeight * ratio;
      final now = DateTime.now();
      final isToday = dates[i].year == now.year &&
          dates[i].month == now.month &&
          dates[i].day == now.day;

      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, baseline.dy - barH, barWidth, barH),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );

      final paint = Paint()
        ..color = isToday ? AppColor.primary : AppColor.primaryContainer;
      canvas.drawRRect(barRect, paint);

      if (v > 0) {
        final label = FormatUtil.rupiahShort(v);
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isToday ? AppColor.primary : AppColor.onSurfaceVariant,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            x + (barWidth - textPainter.width) / 2,
            (baseline.dy - barH - topPad).clamp(0.0, chartHeight - 14),
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.dates != dates;
  }
}
