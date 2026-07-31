import 'package:flutter/material.dart';
import 'package:usahaku/controllers/cash_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/cash_transaction_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Form tambah transaksi kas (pemasukan / pengeluaran).
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final CashController _c = CashController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  CashCategoryModel? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _icons = [
    ('label', 'Label'),
    ('storefront', 'Toko'),
    ('bolt', 'Listrik'),
    ('shopping_cart', 'Belanja'),
    ('card', 'Kartu'),
    ('wallet', 'Dompet'),
    ('handshake', 'Transaksi'),
    ('sell', 'Jualan'),
    ('payments', 'Pembayaran'),
    ('savings', 'Tabungan'),
    ('warning', 'Peringatan'),
  ];

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _typeToggle(),
              const SizedBox(height: 20),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  labelText: 'Nominal',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi', hintText: 'contoh: Listrik bulan ini'),
              ),
              const SizedBox(height: 20),
              _categorySection(),
              const SizedBox(height: 20),
              _dateSection(),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan Transaksi'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _typeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _typeButton(TransactionType.expense, Icons.north_east, 'Pengeluaran'),
          ),
          Expanded(
            child: _typeButton(TransactionType.income, Icons.south_west, 'Pemasukan'),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(TransactionType type, IconData icon, String label) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? (type == TransactionType.income ? AppColor.primary : AppColor.tertiary) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColor.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColor.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection() {
    final categories = _c.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant)),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _categoryCell(null, Icons.label_outline, 'Lainnya'),
              ...categories.map((cat) => _categoryCell(cat, _icon(cat.icon), cat.name)),
              _categoryCell(null, Icons.add_circle_outline, 'Buat', isAdd: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryCell(CashCategoryModel? cat, IconData icon, String label, {bool isAdd = false}) {
    final selected = !isAdd && cat != null && _category?.id == cat.id;
    return GestureDetector(
      onTap: () {
        if (isAdd) {
          _addCategoryDialog();
        } else {
          setState(() => _category = cat);
        }
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected ? AppColor.primary : AppColor.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColor.primary : AppColor.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: selected ? Colors.white : AppColor.onSurfaceVariant, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _addCategoryDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        String selectedIcon = 'label';
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Kategori Baru'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Nama kategori'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _icons.map((ic) {
                      final sel = selectedIcon == ic.$1;
                      return InkWell(
                        onTap: () => setLocal(() => selectedIcon = ic.$1),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sel ? AppColor.primary : AppColor.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_icon(ic.$1), size: 20, color: sel ? Colors.white : AppColor.onSurfaceVariant),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, '${ctrl.text.trim()}|$selectedIcon'),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final parts = name.split('|');
    await _c.addCategory(parts[0], parts.length > 1 ? parts[1] : 'label');
    final created = _c.categories.firstWhere((c) => c.name == parts[0]);
    setState(() => _category = created);
  }

  Widget _dateSection() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, color: AppColor.primary, size: 20),
            const SizedBox(width: 12),
            const Text('Tanggal', style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
            const Spacer(),
            Text(
              FormatUtil.longDate(_date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now().year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  DateTime now() => DateTime.now();

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nominal transaksi')));
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi deskripsi transaksi')));
      return;
    }
    setState(() => _saving = true);
    await _c.add(CashTransactionModel(
      type: _type,
      amount: amount,
      description: _descCtrl.text.trim(),
      categoryId: _category?.id,
      date: _date,
    ));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  IconData _icon(String name) {
    switch (name) {
      case 'storefront':
        return Icons.storefront;
      case 'bolt':
        return Icons.bolt;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'handshake':
        return Icons.handshake_outlined;
      case 'sell':
        return Icons.sell;
      case 'payments':
        return Icons.payments_outlined;
      case 'savings':
        return Icons.savings;
      case 'warning':
        return Icons.warning_amber;
      default:
        return Icons.label_outline;
    }
  }
}
