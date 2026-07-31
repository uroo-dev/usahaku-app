import 'package:flutter/material.dart';
import 'package:usahaku/controllers/produk_controller.dart';
import 'package:usahaku/screens/produk/add_product_screen.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/widgets/empty_state.dart';
import 'package:usahaku/widgets/filter_chip.dart';
import 'package:usahaku/widgets/product_card.dart';

/// Halaman Produk — sesuai produk.html.
class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  final ProdukController _c = ProdukController();
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

  Future<void> _openForm({int? productId}) async {
    final product = productId != null ? _c.products.firstWhere((p) => p.id == productId) : null;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
    );
    _c.load();
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColor.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) await _c.deleteProduct(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    _searchBar(),
                    const SizedBox(height: 12),
                    _filterChips(),
                  ],
                ),
              ),
              Expanded(child: _productList()),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
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
                hintText: 'Cari produk...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    final filters = ['Semua', 'Tersedia', 'Stok Rendah', 'Habis'];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChipWidget(
                  label: f,
                  selected: _c.filter == f,
                  onTap: () => _c.setFilter(f),
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: 'Kategori',
              selected: _c.selectedCategory != null,
              icon: Icons.keyboard_arrow_down,
              onTap: () => showCategorySheet(context, _c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productList() {
    if (_c.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_c.products.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inventory_2,
        title: 'Belum ada produk',
        subtitle: 'Mulai kelola bisnis Anda dengan menambahkan produk pertama.',
        onAction: () => _openForm(),
        actionLabel: 'Tambah Produk',
      );
    }
    return RefreshIndicator(
      onRefresh: _c.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: _c.products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = _c.products[i];
          return ProductCard(
            product: p,
            onEdit: () => _openForm(productId: p.id),
            onDelete: () => _confirmDelete(p.id!),
          );
        },
      ),
    );
  }
}
