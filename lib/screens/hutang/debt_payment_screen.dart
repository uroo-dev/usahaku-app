import 'package:flutter/material.dart';
import 'package:usahaku/controllers/debt_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/debt_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Form catat pembayaran piutang / utang — sesuai piutang-bayar.html.
class DebtPaymentScreen extends StatefulWidget {
  final DebtModel debt;
  const DebtPaymentScreen({super.key, required this.debt});

  @override
  State<DebtPaymentScreen> createState() => _DebtPaymentScreenState();
}

class _DebtPaymentScreenState extends State<DebtPaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  double get remaining => widget.debt.remaining;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = remaining.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nominal pembayaran')));
      return;
    }
    setState(() => _saving = true);
    final controller = widget.debt.type == DebtType.piutang ? ReceivableController() : PayableController();
    await controller.recordPayment(
      widget.debt.id!,
      amount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    controller.dispose();
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPiutang = widget.debt.type == DebtType.piutang;
    return Scaffold(
      appBar: AppBar(title: Text(isPiutang ? 'Bayar Piutang' : 'Bayar Utang')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.debt.relatedName,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sisa ${isPiutang ? 'Piutang' : 'Utang'}: ${FormatUtil.rupiah(remaining)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0', labelText: 'Nominal'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Catatan', hintText: 'Keterangan pembayaran (opsional)'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan Pembayaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
