import 'package:flutter/material.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/sale_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';

/// Halaman detail invoice — menampilkan struk lengkap dari ID sale.
class InvoiceDetailScreen extends StatefulWidget {
  /// Bisa pass langsung SaleModel (sudah ada data) atau hanya saleId
  final SaleModel? sale;
  final int? saleId;

  const InvoiceDetailScreen({super.key, this.sale, this.saleId})
      : assert(sale != null || saleId != null, 'Harus pass sale atau saleId');

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  SaleModel? _sale;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sale != null) {
      _sale = widget.sale;
    } else {
      _loadSale();
    }
  }

  Future<void> _loadSale() async {
    setState(() => _loading = true);
    try {
      final db = DB.instance;
      final saleRow = await (db.select(db.sales)
            ..where((s) => s.id.equals(widget.saleId!)))
          .getSingleOrNull();
      if (saleRow == null) {
        setState(() { _error = 'Invoice tidak ditemukan'; _loading = false; });
        return;
      }
      // Load items
      final itemRows = await (db.select(db.saleItems)
            ..where((i) => i.saleId.equals(saleRow.id)))
          .get();
      final productNames = await _getProductNames(db, itemRows.map((i) => i.productId).toList());
      final items = itemRows.map((r) => SaleItemModel(
        id: r.id,
        saleId: r.saleId,
        productId: r.productId,
        productName: productNames[r.productId] ?? 'Produk',
        quantity: r.quantity,
        price: r.price,
        total: r.total,
      )).toList();
      // Customer name
      String customerName = 'Pelanggan Umum';
      if (saleRow.customerId != null) {
        final cust = await (db.select(db.customers)
              ..where((c) => c.id.equals(saleRow.customerId!)))
            .getSingleOrNull();
        if (cust != null) customerName = cust.name;
      }
      setState(() {
        _sale = SaleModel.fromRow(saleRow, customerName: customerName, items: items);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Map<int, String>> _getProductNames(AppDatabase db, List<int> ids) async {
    if (ids.isEmpty) return {};
    final rows = await (db.select(db.products)
          ..where((p) => p.id.isIn(ids)))
        .get();
    return {for (final r in rows) r.id: r.name};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sale?.invoiceNo ?? 'Detail Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.saleId != null ? _loadSale : null,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColor.error)));
    if (_sale == null) return const Center(child: Text('Tidak ada data'));
    return _invoiceContent(_sale!);
  }

  Widget _invoiceContent(SaleModel sale) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // Header status
        _statusBadge(sale),
        const SizedBox(height: 20),
        // Info invoice
        _infoCard(sale),
        const SizedBox(height: 16),
        // Daftar item
        _itemsCard(sale),
        const SizedBox(height: 16),
        // Ringkasan pembayaran
        _summaryCard(sale),
      ],
    );
  }

  Widget _statusBadge(SaleModel sale) {
    final debtAmount = sale.paidAmount < sale.total && sale.paymentMethod == PaymentMethod.cash
        ? sale.total - sale.paidAmount
        : 0.0;
    final hasDebt = debtAmount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: hasDebt ? AppColor.amber50 : AppColor.green50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasDebt ? AppColor.amber100 : AppColor.green50),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: hasDebt ? AppColor.amber100 : AppColor.green50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasDebt ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: hasDebt ? AppColor.amber700 : AppColor.green700,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDebt ? 'Ada Piutang' : 'Lunas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: hasDebt ? AppColor.amber900 : AppColor.green700,
                  ),
                ),
                Text(
                  hasDebt
                      ? 'Sisa piutang: ${FormatUtil.rupiah(debtAmount)}'
                      : 'Pembayaran selesai',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasDebt ? AppColor.amber800 : AppColor.green700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(SaleModel sale) {
    return _card(
      title: 'Informasi Invoice',
      children: [
        _row('No. Invoice', sale.invoiceNo, bold: true),
        _row('Tanggal', FormatUtil.dateTime(sale.date)),
        _row('Pelanggan', sale.customerName),
        _row('Metode Bayar', sale.paymentMethodLabel),
        if (sale.notes != null && sale.notes!.isNotEmpty)
          _row('Catatan', sale.notes!),
      ],
    );
  }

  Widget _itemsCard(SaleModel sale) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Pesanan (${sale.items.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColor.onSurface),
          ),
          const SizedBox(height: 14),
          if (sale.items.isEmpty)
            const Text('Tidak ada item', style: TextStyle(color: AppColor.onSurfaceVariant))
          else
            ...sale.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColor.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2, color: AppColor.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${FormatUtil.rupiah(item.price)} × ${item.quantity}',
                              style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        FormatUtil.rupiah(item.total),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _summaryCard(SaleModel sale) {
    return _card(
      title: 'Ringkasan Pembayaran',
      children: [
        _row('Subtotal', FormatUtil.rupiah(sale.subtotal)),
        if (sale.discount > 0) _row('Diskon', '- ${FormatUtil.rupiah(sale.discount)}'),
        const Divider(height: 20),
        _row('Total', FormatUtil.rupiah(sale.total), bold: true),
        if (sale.paymentMethod == PaymentMethod.cash) ...[
          _row('Dibayar', FormatUtil.rupiah(sale.paidAmount)),
          if (sale.changeAmount >= 0)
            _row('Kembalian', FormatUtil.rupiah(sale.changeAmount), valueColor: AppColor.green700)
          else
            _row('Sisa Piutang', FormatUtil.rupiah(-sale.changeAmount), valueColor: AppColor.error),
        ],
      ],
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColor.onSurface)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColor.onSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                color: valueColor ?? AppColor.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
