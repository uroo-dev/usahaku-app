import 'package:flutter/material.dart';
import 'package:usahaku/controllers/debt_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/models/debt_model.dart';
import 'package:usahaku/screens/hutang/debt_form_screen.dart';
import 'package:usahaku/screens/hutang/debt_payment_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/filter_chip.dart';

/// Daftar piutang / utang — sesuai piutang.html & utang.html.
class DebtListScreen extends StatefulWidget {
  final DebtType type;
  const DebtListScreen({super.key, required this.type});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  late final DebtBaseController _c;

  bool get isPiutang => widget.type == DebtType.piutang;

  @override
  void initState() {
    super.initState();
    _c = isPiutang ? ReceivableController() : PayableController();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _openDetail(DebtModel d) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DebtDetailScreen(debt: d)),
    );
    _c.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isPiutang ? 'Piutang' : 'Utang'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DebtFormScreen(type: widget.type)),
          );
          _c.load();
        },
        icon: const Icon(Icons.add),
        label: Text(isPiutang ? 'Tambah Piutang' : 'Tambah Utang'),
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
                _summaryCarousel(),
                _filterRow(),
                if (_c.debts.isEmpty)
                  _empty()
                else
                  ..._c.debts.map((d) => _debtCard(d)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCarousel() {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _summaryCard(
            width: 200,
            color: AppColor.primaryContainer,
            textColor: AppColor.onPrimaryContainer,
            label: 'Total ${isPiutang ? 'Piutang' : 'Utang'}',
            value: FormatUtil.rupiah(_c.totalRemaining),
          ),
          _summaryCard(
            width: 200,
            color: AppColor.surfaceContainer,
            textColor: AppColor.onSurface,
            label: 'Dibayar Bln Ini',
            value: FormatUtil.rupiah(_c.totalPaidThisMonth),
          ),
          _summaryCard(
            width: 200,
            color: AppColor.errorContainer,
            textColor: AppColor.onErrorContainer,
            label: 'Jatuh Tempo',
            value: FormatUtil.rupiah(_c.overdueTotal),
          ),
          _summaryCard(
            width: 200,
            color: AppColor.surfaceContainer,
            textColor: AppColor.onSurface,
            label: 'Akan Datang',
            value: FormatUtil.rupiah(_c.comingTotal),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required double width,
    required Color color,
    required Color textColor,
    required String label,
    required String value,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Semua', 'Belum Lunas', 'Sebagian', 'Lunas'].map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipWidget(
                      label: f,
                      selected: _c.statusFilter == f,
                      onTap: () => _c.setStatusFilter(f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColor.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune, size: 20, color: AppColor.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _debtCard(DebtModel d) {
    final initials = _initials(d.relatedName);
    return GestureDetector(
      onTap: () => _openDetail(d),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColor.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: d.isOverdue
                      ? AppColor.secondaryFixed
                      : d.status == DebtStatus.partial
                          ? AppColor.tertiaryFixed
                          : AppColor.primaryFixed,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: d.isOverdue
                          ? AppColor.onSecondaryFixed
                          : d.status == DebtStatus.partial
                              ? AppColor.onTertiaryFixed
                              : AppColor.onPrimaryFixed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.relatedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.description ?? '${isPiutang ? 'Piutang' : 'Utang'} #${d.id}'} • ${FormatUtil.date(d.dueDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _statusBadge(d),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColor.outlineVariant))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sisa Tagihan', style: TextStyle(fontSize: 11, color: AppColor.onSurfaceVariant)),
                      Text(
                        FormatUtil.rupiah(d.remaining),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: d.remaining > 0 && d.isOverdue ? AppColor.error : AppColor.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        d.isOverdue ? 'Jatuh Tempo' : 'Jatuh Tempo',
                        style: TextStyle(fontSize: 11, color: d.isOverdue ? AppColor.error : AppColor.onSurfaceVariant),
                      ),
                      Text(
                        FormatUtil.date(d.dueDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!d.isLunas) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    final paid = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => DebtPaymentScreen(debt: d)),
                    );
                    if (paid == true) _c.load();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(isPiutang ? 'Catat Pembayaran' : 'Bayar Utang'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(DebtModel d) {
    final (label, bg, fg) = switch (d.status) {
      DebtStatus.paid => ('Lunas', AppColor.successContainer, AppColor.onSuccessContainer),
      DebtStatus.partial => (d.isOverdue ? 'Sebagian • Telat' : 'Sebagian', AppColor.tertiaryContainer, AppColor.onTertiaryContainer),
      DebtStatus.pending => (d.isOverdue ? 'Terlambat' : 'Belum Lunas', AppColor.primaryContainer, AppColor.onPrimaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.5),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, size: 64, color: AppColor.outline),
          const SizedBox(height: 12),
          const Text(
            'Semua Beres!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Tidak ada ${isPiutang ? 'piutang' : 'utang'} yang tertunda.',
            style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant),
          ),
        ],
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

/// Detail piutang/utang + riwayat pembayaran — sesuai detail-piutang.html.
class _DebtDetailScreen extends StatefulWidget {
  final DebtModel debt;
  const _DebtDetailScreen({required this.debt});

  @override
  State<_DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<_DebtDetailScreen> {
  final ReceivableController _c = ReceivableController();
  List<DebtPaymentModel> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _c.paymentHistory(widget.debt.id!);
    if (mounted) setState(() => _history = history);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.debt;
    final isPiutang = d.type == DebtType.piutang;
    return Scaffold(
      appBar: AppBar(title: Text(isPiutang ? 'Detail Piutang' : 'Detail Utang')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.relatedName,
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  FormatUtil.rupiah(d.remaining),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'dari ${FormatUtil.rupiah(d.amount)} • sisa ${d.paidAmount > 0 ? 'terbayar ${FormatUtil.rupiah(d.paidAmount)}' : 'belum dibayar'}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColor.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _infoRow('Status', d.statusLabel),
                _infoRow('Jatuh Tempo', FormatUtil.date(d.dueDate)),
                _infoRow('Keterangan', d.description ?? '-'),
                if (d.relatedPhone.isNotEmpty) _infoRow('Kontak', d.relatedPhone),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Riwayat Pembayaran',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.onSurface),
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const Text('Belum ada pembayaran.', style: TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant))
          else
            ..._history.map((h) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColor.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.notes ?? 'Pembayaran', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(
                              FormatUtil.dateTime(h.date),
                              style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        FormatUtil.rupiah(h.amount),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColor.success),
                      ),
                    ],
                  ),
                )),
          if (!d.isLunas) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  final paid = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => DebtPaymentScreen(debt: d)),
                  );
                  if (paid == true) _load();
                },
                icon: const Icon(Icons.payments_outlined),
                label: Text(isPiutang ? 'Catat Pembayaran' : 'Bayar Utang'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
