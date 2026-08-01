import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usahaku/controllers/sale_controller.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/barcode_scanner_sheet.dart';
import 'package:usahaku/widgets/filter_chip.dart';

import 'checkout_screen.dart';

/// Penjualan (POS) — sesuai penjualan.html.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SaleController _c = SaleController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Force landscape untuk tampilan grid POS yang lebih baik
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _c.load();
  }

  @override
  void dispose() {
    // Kembalikan orientasi normal saat keluar dari POS
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _c.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Scan barcode lalu cari produk yang cocok
  Future<void> _scanBarcode() async {
    final result = await BarcodeScannerSheet.show(context);
    if (result == null || !mounted) return;
    _searchCtrl.text = result;
    _c.setQuery(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload produk',
            onPressed: () => _c.load(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _searchSection(),
              ),
              const SizedBox(height: 8),
              _categoryRow(),
              Expanded(child: _productGrid()),
              if (_c.cart.isNotEmpty) _checkoutBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _searchSection() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
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
                hintText: 'Cari produk atau scan barcode...',
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
              color: AppColor.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.qr_code_scanner, color: AppColor.primary, size: 20),
              tooltip: 'Scan Barcode',
              onPressed: _scanBarcode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: 'Semua',
              selected: _c.selectedCategory == null,
              onTap: () => _c.setCategory(null),
            ),
          ),
          ..._c.categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChipWidget(
                  label: cat.name,
                  selected: _c.selectedCategory == cat.name,
                  onTap: () => _c.setCategory(cat.name),
                ),
              )),
        ],
      ),
    );
  }

  Widget _productGrid() {
    if (_c.isLoading) return const Center(child: CircularProgressIndicator());
    if (_c.filteredProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Produk tidak ditemukan', style: TextStyle(fontSize: 14, color: AppColor.onSurfaceVariant)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _c.filteredProducts.length,
      itemBuilder: (context, i) {
        final p = _c.filteredProducts[i];
        final inCart = _c.cart.where((x) => x.product.id == p.id).firstOrNull;
        return _productGridCard(p, inCart?.quantity);
      },
    );
  }

  Widget _productGridCard(dynamic p, int? qtyInCart) {
    final outOfStock = p.isOutOfStock;
    return GestureDetector(
      onTap: outOfStock ? null : () => _c.addToCart(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: qtyInCart != null
              ? AppColor.primaryContainer
              : outOfStock
                  ? AppColor.surfaceContainerLow.withValues(alpha: 0.6)
                  : AppColor.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: qtyInCart != null
                ? AppColor.primary.withValues(alpha: 0.4)
                : AppColor.outlineVariant.withValues(alpha: 0.3),
            width: qtyInCart != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar produk
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: p.imagePath != null && p.imagePath!.isNotEmpty
                    ? Image.file(File(p.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: AppColor.surfaceContainer,
                        child: Icon(
                          Icons.inventory_2,
                          color: outOfStock ? AppColor.outline : AppColor.primary,
                          size: 28,
                        ),
                      ),
              ),
            ),
            // Info + qty controls
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: outOfStock ? AppColor.outline : AppColor.onSurface,
                      ),
                    ),
                    Text(
                      FormatUtil.rupiah(p.sellPrice),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: outOfStock ? AppColor.outline : AppColor.primary,
                      ),
                    ),
                    if (outOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColor.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Habis', style: TextStyle(fontSize: 10, color: AppColor.error, fontWeight: FontWeight.w700)),
                      )
                    else if (qtyInCart != null)
                      // Qty stepper
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _c.decrement(p.id!),
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.remove, color: Colors.white, size: 16),
                            ),
                          ),
                          Text(
                            '$qtyInCart',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColor.primary),
                          ),
                          GestureDetector(
                            onTap: () => _c.increment(p.id!),
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stok: ${p.stock}',
                            style: TextStyle(
                              fontSize: 10,
                              color: p.isLowStock ? AppColor.tertiary : AppColor.onSurfaceVariant,
                            ),
                          ),
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(color: AppColor.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.add, color: AppColor.primary, size: 16),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkoutBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColor.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.shopping_basket, color: AppColor.primary, size: 22)),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: AppColor.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: Text(
                      '${_c.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_c.cart.length} Item terpilih', style: const TextStyle(fontSize: 12, color: AppColor.onSurfaceVariant)),
                Text(
                  FormatUtil.rupiah(_c.total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckoutScreen(controller: _c)),
              );
              if (result == true && mounted) _c.load();
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 52)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bayar'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
