import 'package:flutter/material.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Field bertanda: label kecil di atas + border (sesuai template form).
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColor.onSurfaceVariant),
          ),
        ),
        child,
      ],
    );
  }
}

/// Stepper +/- untuk input stok.
class StepperField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  const StepperField({super.key, required this.value, required this.onChanged, this.min = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _btn(Icons.remove, () => onChanged((value - 1).clamp(min, 999999))),
          Expanded(
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.onSurface),
              ),
            ),
          ),
          _btn(Icons.add, () => onChanged((value + 1).clamp(min, 999999))),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 56,
        child: Icon(icon, size: 20, color: AppColor.onSurfaceVariant),
      ),
    );
  }
}
