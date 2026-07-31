import 'package:flutter/material.dart';
import 'package:usahaku/controllers/cash_controller.dart';
import 'package:usahaku/models/cash_transaction_model.dart';
import 'package:usahaku/screens/kas/transaction_form_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/filter_chip.dart';

/// Kas — sesuai kas.html: saldo total, filter periode, daftar transaksi per hari.
class KasScreen extends StatefulWidget {
  const KasScreen({super.key});

  @override
  State<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends State<KasScreen> {
  final CashController _c = CashController();

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );
    if (added == true) _c.load();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _PeriodSheet(current: _c.period),
    );
    if (result != null) _c.setPeriod(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kas'),
            Text(
              _c.period == 'Semua' ? 'Semua transaksi' : _c.period,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColor.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Transaksi'),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (_c.isLoading) return const Center(child: CircularProgressIndicator());
          return RefreshIndicator(
            onRefresh: _c.load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                _balanceCard(),
                _chips(),
                if (_c.transactions.isEmpty)
                  const SizedBox(height: 200)
                else
                  _groupedList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColor.primary.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Total Saldo Kas',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            FormatUtil.rupiah(_c.balanceTotal),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.south_west, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pemasukan', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            FormatUtil.rupiahShort(_c.incomeTotal),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.north_east, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pengeluaran', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            FormatUtil.rupiahShort(_c.expenseTotal),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFB596)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        children: ['Hari ini', 'Minggu ini', 'Bulan ini', 'Semua'].map((period) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: period,
              selected: _c.period == period,
              onTap: () => _c.setPeriod(period),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _groupedList() {
    final groups = <String, List<CashTransactionModel>>{};
    for (final t in _c.transactions) {
      final key = _dayKey(t.date);
      groups.putIfAbsent(key, () => []).add(t);
    }
    final entries = groups.entries.toList()..sort((a, b) => _keyDate(b.key).compareTo(_keyDate(a.key)));

    return Column(
      children: entries.map((entry) {
        final dayTx = entry.value;
        final net = dayTx.fold<double>(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_dayLabel(entry.key), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant)),
                  Text(
                    FormatUtil.rupiah(net),
                    style: TextStyle(fontSize: 12, color: net >= 0 ? AppColor.primary : AppColor.error),
                  ),
                ],
              ),
            ),
            ...dayTx.map((t) => _transactionTile(t)),
          ],
        );
      }).toList(),
    );
  }

  Widget _transactionTile(CashTransactionModel t) {
    return GestureDetector(
      onTap: () async {
        final deleted = await showModalBottomSheet<bool>(
          context: context,
          builder: (ctx) => _TransactionActionSheet(t: t),
        );
        if (deleted == true) {
          _c.delete(t.id!);
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (t.isIncome ? AppColor.primary : AppColor.tertiary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                _iconForCategory(t.categoryIcon),
                color: t.isIncome ? AppColor.primary : AppColor.tertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.categoryName} • ${FormatUtil.time(t.date)}',
                    style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '${t.isIncome ? '+' : '-'} ${FormatUtil.rupiah(t.amount)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: t.isIncome ? AppColor.primary : AppColor.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String name) {
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

  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _keyDate(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  String _dayLabel(String key) {
    final d = _keyDate(key);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'Hari Ini, ${FormatUtil.dayShort(d)}';
    if (d == today.subtract(const Duration(days: 1))) return 'Kemarin, ${FormatUtil.dayShort(d)}';
    return FormatUtil.longDate(d);
  }
}

class _PeriodSheet extends StatelessWidget {
  final String current;
  const _PeriodSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    const options = ['Hari ini', 'Minggu ini', 'Bulan ini', 'Semua'];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Filter Periode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ...options.map((o) => ListTile(
                leading: Icon(
                  o == 'Hari ini'
                      ? Icons.today
                      : o == 'Minggu ini'
                          ? Icons.date_range
                          : o == 'Bulan ini'
                              ? Icons.calendar_month
                              : Icons.all_inclusive,
                  color: current == o ? AppColor.primary : null,
                ),
                title: Text(o),
                trailing: current == o ? const Icon(Icons.check, color: AppColor.primary) : null,
                onTap: () => Navigator.pop(context, o),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TransactionActionSheet extends StatelessWidget {
  final CashTransactionModel t;
  const _TransactionActionSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(t.isIncome ? Icons.south_west : Icons.north_east, color: t.isIncome ? AppColor.primary : AppColor.error),
            title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${FormatUtil.longDate(t.date)} • ${FormatUtil.rupiah(t.amount)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColor.error),
            title: const Text('Hapus Transaksi', style: TextStyle(color: AppColor.error)),
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
