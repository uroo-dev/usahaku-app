import 'package:flutter/material.dart';
import 'package:usahaku/controllers/sale_controller.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/format_util.dart';
import 'package:usahaku/widgets/filter_chip.dart';
import 'package:usahaku/widgets/product_card.dart';

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
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan'),
        automaticallyImplyLeading: false,
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
            child: const Icon(Icons.qr_code_scanner, color: AppColor.primary, size: 20),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _c.filteredProducts.length,
      itemBuilder: (context, i) {
        final p = _c.filteredProducts[i];
        final inCart = _c.cart.where((x) => x.product.id == p.id).firstOrNull;
        return GestureDetector(
          onTap: () => _c.addToCart(p),
          child: Stack(
            children: [
              ProductCard(product: p, onTap: () => _c.addToCart(p)),
              if (inCart != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(color: AppColor.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18, color: AppColor.primary),
                              onPressed: () => _c.decrement(p.id!),
                            ),
                            Text(
                              '${inCart.quantity}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.onSurface),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18, color: AppColor.primary),
                              onPressed: () => _c.increment(p.id!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
