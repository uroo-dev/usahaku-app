import 'package:flutter/material.dart';
import 'package:usahaku/controllers/customer_controller.dart';
import 'package:usahaku/controllers/sale_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/customer_model.dart';
import 'package:usahaku/screens/penjualan/payment_success_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Checkout: daftar item, pelanggan, diskon, catatan, metode bayar.
class CheckoutScreen extends StatefulWidget {
  final SaleController controller;
  const CheckoutScreen({super.key, required this.controller});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _saving = false;

  SaleController get c => widget.controller;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final customer = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CustomerPickerSheet(),
    );
    if (customer != null) c.setCustomer(customer);
  }

  Future<void> _checkout() async {
    final method = c.paymentMethod;
    if (method == PaymentMethod.qris && c.qrisPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan gambar QRIS di Pengaturan terlebih dahulu')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final sale = await c.checkout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(sale: sale)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              _itemsSection(),
              const SizedBox(height: 20),
              _customerSection(),
              const SizedBox(height: 20),
              _discountSection(),
              const SizedBox(height: 20),
              _notesSection(),
              const SizedBox(height: 20),
              _paymentSection(),
              const SizedBox(height: 20),
              _summarySection(),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: AppColor.surface.withValues(alpha: 0.95),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _checkout,
              icon: Icon(_saving ? Icons.hourglass_top : Icons.payments_outlined, size: 20),
              label: Text(_saving ? 'Memproses...' : 'Bayar ${FormatUtil.rupiah(c.total)}'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemsSection() {
    return Column(
      children: c.cart.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColor.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2, color: AppColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                    ),
                    Text(
                      '${FormatUtil.rupiah(item.product.sellPrice)} x ${item.quantity}',
                      style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                FormatUtil.rupiah(item.subtotal),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.onSurface),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _customerSection() {
    final name = c.selectedCustomer?.name ?? 'Pilih pelanggan';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pelanggan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColor.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickCustomer,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColor.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_search, color: AppColor.outline, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.selectedCustomer == null ? AppColor.onSurfaceVariant : AppColor.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person_add_alt, color: AppColor.primary),
                onPressed: _addNewCustomer,
              ),
            ],
          ),
          if (c.selectedCustomer == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Kosong = "Pelanggan Umum"',
                style: TextStyle(fontSize: 11, color: AppColor.outline),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addNewCustomer() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Pelanggan Baru'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nama pelanggan'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Simpan')),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final customerCtrl = CustomerController();
    await customerCtrl.add(CustomerModel(name: name));
    await customerCtrl.load();
    final found = customerCtrl.customers.firstWhere((x) => x.name == name);
    c.setCustomer(found);
    customerCtrl.dispose();
  }

  Widget _discountSection() {
    return Row(
      children: [
        const Icon(Icons.sell_outlined, color: AppColor.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _discountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) => c.setDiscount(double.tryParse(v) ?? 0),
            decoration: const InputDecoration(hintText: 'Diskon (Rp)', prefixText: 'Rp '),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            _discountCtrl.clear();
            c.setDiscount(0);
          },
          child: const Text('Hapus'),
        ),
      ],
    );
  }

  Widget _notesSection() {
    return TextField(
      controller: _notesCtrl,
      onChanged: (v) => c.notes = v,
      maxLines: 2,
      decoration: const InputDecoration(hintText: 'Catatan (opsional)', alignLabelWithHint: true),
    );
  }

  Widget _paymentSection() {
    final options = [
      (PaymentMethod.cash, Icons.payments_outlined, 'Tunai'),
      (PaymentMethod.qris, Icons.qr_code_2, 'QRIS'),
      (PaymentMethod.transfer, Icons.account_balance_outlined, 'Transfer'),
      (PaymentMethod.debt, Icons.receipt_long, 'Hutang'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pembayaran',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.onSurface),
        ),
        const SizedBox(height: 12),
        Row(
          children: options.map((opt) {
            final selected = c.paymentMethod == opt.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => c.setPaymentMethod(opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColor.primary : AppColor.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(opt.$2, color: selected ? Colors.white : AppColor.onSurfaceVariant, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          opt.$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColor.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _summarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _sumRow('Subtotal', FormatUtil.rupiah(c.subtotal)),
          const SizedBox(height: 8),
          _sumRow('Diskon', '- ${FormatUtil.rupiah(c.discount)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _sumRow('Total', FormatUtil.rupiah(c.total), bold: true, big: true),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, {bool bold = false, bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: big ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppColor.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 20 : 13,
            fontWeight: FontWeight.w700,
            color: bold ? AppColor.primary : AppColor.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet pilih pelanggan.
class _CustomerPickerSheet extends StatefulWidget {
  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final CustomerController _c = CustomerController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pilih Pelanggan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: _c.setQuery,
                  decoration: const InputDecoration(hintText: 'Cari nama atau nomor HP...'),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColor.surfaceContainerHigh,
                        child: Icon(Icons.person_outline),
                      ),
                      title: const Text('Pelanggan Umum'),
                      subtitle: const Text('Tanpa data pelanggan'),
                      onTap: () {
                        Navigator.pop(context, null);
                      },
                    ),
                    ..._c.customers.map((c) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColor.secondaryContainer.withValues(alpha: 0.3),
                            child: Text(
                              _initials(c.name),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.secondary),
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: Text(c.phone.isEmpty ? 'No HP tidak ada' : c.phone),
                          onTap: () => Navigator.pop(context, c),
                        )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
