import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:usahaku/controllers/customer_controller.dart';
import 'package:usahaku/controllers/debt_controller.dart';
import 'package:usahaku/controllers/supplier_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/customer_model.dart';
import 'package:usahaku/models/supplier_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Form tambah piutang / utang manual.
class DebtFormScreen extends StatefulWidget {
  final DebtType type;
  const DebtFormScreen({super.key, required this.type});

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _relatedNameCtrl = TextEditingController();
  final _relatedPhoneCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;
  bool _isPiutang = true;

  @override
  void initState() {
    super.initState();
    _isPiutang = widget.type == DebtType.piutang;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _relatedNameCtrl.dispose();
    _relatedPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRelated() async {
    if (_isPiutang) {
      final customers = CustomerController();
      await customers.load();
      if (!mounted) return;
      final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pilih Pelanggan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ...customers.customers.map((c) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(c.name),
                    subtitle: Text(c.phone.isEmpty ? 'No HP tidak ada' : c.phone),
                    onTap: () {
                      _relatedNameCtrl.text = c.name;
                      _relatedPhoneCtrl.text = c.phone;
                      Navigator.pop(ctx, c.name);
                    },
                  )),
            ],
          ),
        ),
      );
      customers.dispose();
      if (selected != null) setState(() {});
    } else {
      final suppliers = SupplierController();
      await suppliers.load();
      if (!mounted) return;
      final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pilih Supplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ...suppliers.suppliers.map((s) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.factory_outlined)),
                    title: Text(s.name),
                    subtitle: Text(s.phone.isEmpty ? 'No HP tidak ada' : s.phone),
                    onTap: () {
                      _relatedNameCtrl.text = s.name;
                      _relatedPhoneCtrl.text = s.phone;
                      Navigator.pop(ctx, s.name);
                    },
                  )),
            ],
          ),
        ),
      );
      suppliers.dispose();
      if (selected != null) setState(() {});
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nominal tagihan')));
      return;
    }
    if (_relatedNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isPiutang ? 'Pilih pelanggan terlebih dahulu' : 'Pilih supplier terlebih dahulu')),
      );
      return;
    }
    setState(() => _saving = true);

    final controller = _isPiutang ? ReceivableController() : PayableController();

    int relatedId;
    if (_isPiutang) {
      final customerCtrl = CustomerController();
      await customerCtrl.load();
      final existing = customerCtrl.customers.where((c) => c.name == _relatedNameCtrl.text.trim()).firstOrNull;
      if (existing != null) {
        relatedId = existing.id!;
      } else {
        await customerCtrl.add(CustomerModel(name: _relatedNameCtrl.text.trim(), phone: _relatedPhoneCtrl.text.trim()));
        await customerCtrl.load();
        relatedId = customerCtrl.customers.last.id!;
      }
      customerCtrl.dispose();
    } else {
      final supplierCtrl = SupplierController();
      await supplierCtrl.load();
      final existing = supplierCtrl.suppliers.where((s) => s.name == _relatedNameCtrl.text.trim()).firstOrNull;
      if (existing != null) {
        relatedId = existing.id!;
      } else {
        await supplierCtrl.add(SupplierModel(name: _relatedNameCtrl.text.trim(), phone: _relatedPhoneCtrl.text.trim()));
        await supplierCtrl.load();
        relatedId = supplierCtrl.suppliers.last.id!;
      }
      supplierCtrl.dispose();
    }

    await _insertDebt(controller, relatedId, amount);

    controller.dispose();
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  Future<void> _insertDebt(DebtBaseController controller, int relatedId, double amount) async {
    final db = DB.instance;
    await db.into(db.debts).insert(DebtsCompanion.insert(
          type: widget.type,
          relatedId: relatedId,
          amount: Value(amount),
          dueDate: _dueDate,
          description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
        ));
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isPiutang ? 'Tambah Piutang' : 'Tambah Utang')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0', labelText: 'Nominal'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickRelated,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_search, color: AppColor.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPiutang ? 'Pelanggan *' : 'Supplier *',
                            style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _relatedNameCtrl.text.trim().isEmpty ? 'Pilih dari daftar' : _relatedNameCtrl.text.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _relatedNameCtrl.text.trim().isEmpty ? AppColor.onSurfaceVariant : AppColor.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColor.outline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: AppColor.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Jatuh Tempo', style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
                    const Spacer(),
                    Text(
                      FormatUtil.date(_dueDate),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Keterangan', hintText: 'contoh: Pembelian bahan baku'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
