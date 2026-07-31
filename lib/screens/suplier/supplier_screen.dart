import 'package:flutter/material.dart';
import 'package:usahaku/controllers/supplier_controller.dart';
import 'package:usahaku/models/supplier_model.dart';
import 'package:usahaku/screens/suplier/supplier_form_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/filter_chip.dart';

/// Supplier — sesuai suplier.html: cari, chip filter, daftar kartu supplier.
class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final SupplierController _c = SupplierController();
  final _searchCtrl = TextEditingController();
  String _filter = 'Semua';
  final Map<int, double> _payable = {};

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPayable(SupplierModel s) async {
    final payable = await _c.remainingPayable(s.id!);
    if (mounted) setState(() => _payable[s.id!] = payable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const SupplierFormScreen()),
          );
          if (saved == true) _c.load();
        },
        child: const Icon(Icons.add_business_outlined),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _search(),
              ),
              _chips(),
              Expanded(
                child: _c.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _c.suppliers.isEmpty
                        ? _empty()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            children: _c.suppliers.map((s) {
                              _loadPayable(s);
                              return _supplierCard(s);
                            }).toList(),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _search() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColor.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _c.setQuery,
              decoration: const InputDecoration(
                hintText: 'Cari supplier...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColor.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune, color: AppColor.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        children: ['Semua', 'Ada Hutang'].map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: f,
              selected: _filter == f,
              onTap: () {
                setState(() => _filter = f);
                _c.setQuery(f == 'Ada Hutang' ? '' : _searchCtrl.text);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _supplierCard(SupplierModel s) {
    final payable = _payable[s.id] ?? 0;
    final hasDebt = payable > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasDebt ? AppColor.errorContainer : AppColor.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.factory_outlined, color: hasDebt ? AppColor.onErrorContainer : AppColor.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                    ),
                    if (s.phone.isNotEmpty)
                      Text(
                        s.phone,
                        style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (hasDebt)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Hutang',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.onErrorContainer),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hutang', style: TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      FormatUtil.rupiah(payable),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.error),
                    ),
                  ],
                ),
              ),
              if (s.address.isNotEmpty)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColor.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _iconBtn(Icons.call_outlined, () {}),
              const SizedBox(width: 8),
              _iconBtn(Icons.chat_bubble_outline, () {}),
              const Spacer(),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => _openForm(s),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColor.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColor.primary),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: AppColor.surfaceContainer, shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_outlined, size: 48, color: AppColor.outlineVariant),
          ),
          const SizedBox(height: 16),
          const Text(
            'Supplier tidak ditemukan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.onSurface),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba cari dengan nama atau nomor telepon lain.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(SupplierModel s) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: s)),
    );
    if (saved == true) _c.load();
  }
}
