import 'package:flutter/material.dart';
import 'package:usahaku/controllers/customer_controller.dart';
import 'package:usahaku/models/customer_model.dart';
import 'package:usahaku/screens/pelanggan/customer_form_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/filter_chip.dart';

/// Pelanggan — sesuai pelanggan.html: cari, chip filter, daftar kartu pelanggan.
class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerController _c = CustomerController();
  final _searchCtrl = TextEditingController();
  String _filter = 'Semua';
  final Map<int, double> _spending = {};
  final Map<int, double> _receivable = {};
  final Map<int, String> _lastActivity = {};

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

  Future<void> _loadStats(CustomerModel c) async {
    final spending = await _c.totalSpending(c.id!);
    final receivable = await _c.remainingReceivable(c.id!);
    if (mounted) {
      setState(() {
        _spending[c.id!] = spending;
        _receivable[c.id!] = receivable;
        _lastActivity[c.id!] = spending > 0 ? 'Ada transaksi' : '-';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
          if (saved == true) _c.load();
        },
        child: const Icon(Icons.person_add),
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
                    : _c.customers.isEmpty
                        ? _empty()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            children: _c.customers.map((c) {
                              _loadStats(c);
                              return _customerCard(c);
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
        color: AppColor.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColor.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _c.setQuery,
              decoration: const InputDecoration(
                hintText: 'Cari pelanggan...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColor.outlineVariant),
            onPressed: () {},
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
        children: ['Semua', 'Punya Piutang'].map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: f,
              selected: _filter == f,
              onTap: () {
                setState(() => _filter = f);
                _c.setQuery(f == 'Punya Piutang' ? '' : _searchCtrl.text);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _customerCard(CustomerModel c) {
    final spending = _spending[c.id] ?? 0;
    final receivable = _receivable[c.id] ?? 0;
    final hasDebt = receivable > 0;
    final initials = _initials(c.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: hasDebt ? AppColor.errorContainer : AppColor.secondaryContainer.withValues(alpha: 0.5),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: hasDebt ? AppColor.onErrorContainer : AppColor.secondary,
                        ),
                      ),
                    ),
                    if (hasDebt)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColor.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.priority_high, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                            ),
                          ),
                          if (hasDebt)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColor.errorContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Piutang',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.onErrorContainer),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        c.phone.isEmpty ? 'No HP tidak ada' : c.phone,
                        style: const TextStyle(fontSize: 12, color: AppColor.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statBlock('Sisa Piutang', FormatUtil.rupiah(receivable), color: AppColor.error),
                ),
                Expanded(
                  child: _statBlock('Total Belanja', FormatUtil.rupiah(spending)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColor.surfaceVariant))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terakhir: ${_lastActivity[c.id] ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: AppColor.outline),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColor.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColor.secondary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _openForm(c);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColor.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock(String label, String value, {Color color = AppColor.onSurface}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
      ],
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
            child: const Icon(Icons.person_search, size: 48, color: AppColor.outlineVariant),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pelanggan tidak ditemukan',
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

  Future<void> _openForm(CustomerModel c) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: c)),
    );
    if (saved == true) _c.load();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
