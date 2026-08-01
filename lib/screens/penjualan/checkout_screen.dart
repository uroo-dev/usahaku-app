import 'dart:io';

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
  final _paidCtrl = TextEditingController();
  bool _saving = false;

  SaleController get c => widget.controller;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    _paidCtrl.dispose();
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

  /// Tampilkan popup QRIS dengan nominal, lalu checkout
  Future<void> _showQrisPopup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _QrisPaymentDialog(
        total: c.total,
        qrisPath: c.qrisPath,
      ),
    );
    if (confirmed == true) await _doCheckout();
  }

  Future<void> _checkout() async {
    final method = c.paymentMethod;
    if (method == PaymentMethod.qris) {
      await _showQrisPopup();
      return;
    }
    // Cash: validasi
    if (method == PaymentMethod.cash) {
      final paid = c.paidAmount;
      if (paid <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan jumlah bayar terlebih dahulu')),
        );
        return;
      }
      if (paid < c.total && c.selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih pelanggan untuk mencatat piutang')),
        );
        return;
      }
    }
    await _doCheckout();
  }

  Future<void> _doCheckout() async {
    setState(() => _saving = true);
    try {
      final sale = await c.checkout();
      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(sale: sale)),
      );
      if (!mounted) return;
      Navigator.pop(context, result ?? true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal checkout: $e')),
        );
      }
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
      bottomNavigationBar: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          // Tentukan apakah tombol aktif
          bool canPay = !_saving;
          String buttonLabel = 'Bayar ${FormatUtil.rupiah(c.total)}';
          if (c.paymentMethod == PaymentMethod.cash) {
            if (c.paidAmount <= 0) {
              canPay = false;
              buttonLabel = 'Masukkan jumlah bayar';
            } else if (c.paidAmount < c.total && c.selectedCustomer == null) {
              canPay = false;
              buttonLabel = 'Pilih pelanggan untuk hutang';
            } else if (c.paidAmount < c.total && c.selectedCustomer != null) {
              buttonLabel = 'Catat Hutang';
            }
          }
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            color: AppColor.surface.withValues(alpha: 0.95),
            child: SafeArea(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (canPay && !_saving) ? _checkout : null,
                  icon: Icon(_saving ? Icons.hourglass_top : Icons.payments_outlined, size: 20),
                  label: Text(_saving ? 'Memproses...' : buttonLabel),
                ),
              ),
            ),
          );
        },
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColor.primary : AppColor.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(opt.$2, color: selected ? Colors.white : AppColor.onSurfaceVariant, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          opt.$3,
                          style: TextStyle(
                            fontSize: 13,
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
        const SizedBox(height: 16),
        // Input bayar untuk Cash
        if (c.paymentMethod == PaymentMethod.cash) _cashInputSection(),
      ],
    );
  }

  Widget _cashInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jumlah Bayar',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _paidCtrl,
          keyboardType: TextInputType.number,
          onChanged: (v) => c.setPaidAmount(double.tryParse(v.replaceAll('.', '')) ?? 0),
          decoration: const InputDecoration(
            hintText: '0',
            prefixText: 'Rp ',
          ),
        ),
        const SizedBox(height: 8),
        // Tombol nominal cepat
        Wrap(
          spacing: 8,
          children: _quickAmounts().map((amount) {
            return ActionChip(
              label: Text(
                amount >= 1000
                    ? 'Rp ${(amount / 1000).toStringAsFixed(0)}rb'
                    : 'Pas',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                final val = amount == 0 ? c.total : amount;
                _paidCtrl.text = val.toStringAsFixed(0);
                c.setPaidAmount(val);
              },
            );
          }).toList(),
        ),
        if (c.paidAmount > 0) ...[
          const SizedBox(height: 8),
          _cashStatusRow(),
        ],
      ],
    );
  }

  List<double> _quickAmounts() {
    final t = c.total;
    // "Pas" = 0 marker, lalu nominal di atasnya
    final List<double> amounts = [0]; // 0 = uang pas
    final steps = [5000, 10000, 20000, 50000, 100000];
    for (final s in steps) {
      final rounded = (t / s).ceil() * s;
      if (!amounts.contains(rounded.toDouble()) && rounded >= t) {
        amounts.add(rounded.toDouble());
        if (amounts.length >= 5) break;
      }
    }
    return amounts;
  }

  Widget _cashStatusRow() {
    final change = c.paidAmount - c.total;
    if (change >= 0) {
      // Kembalian
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.green50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kembalian', style: TextStyle(fontSize: 13, color: AppColor.green700, fontWeight: FontWeight.w600)),
            Text(
              'Rp ${change.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.green700),
            ),
          ],
        ),
      );
    } else {
      // Kurang / Piutang
      final debt = -change;
      final hasCustomer = c.selectedCustomer != null;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasCustomer ? AppColor.amber50 : AppColor.red50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasCustomer ? 'Akan jadi piutang' : 'Kurang (butuh pelanggan)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasCustomer ? AppColor.amber700 : AppColor.red700),
            ),
            Text(
              'Rp ${debt.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: hasCustomer ? AppColor.amber700 : AppColor.red700),
            ),
          ],
        ),
      );
    }
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

/// Dialog popup QRIS — tampilkan nominal + gambar QR, lalu konfirmasi bayar.
class _QrisPaymentDialog extends StatelessWidget {
  final double total;
  final String? qrisPath;
  const _QrisPaymentDialog({required this.total, this.qrisPath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bayar via QRIS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan kode QR di bawah untuk membayar',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Nominal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColor.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL PEMBAYARAN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColor.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatUtil.rupiah(total),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColor.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Gambar QRIS
            if (qrisPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(qrisPath!),
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 80, color: AppColor.onSurfaceVariant),
                    SizedBox(height: 8),
                    Text(
                      'Gambar QRIS belum diatur\nPergi ke Pengaturan → QRIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Sudah Dibayar'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
