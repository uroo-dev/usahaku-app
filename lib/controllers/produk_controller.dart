import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/product_model.dart';

import 'base_controller.dart';

/// Manajemen produk + kategori dinamis (SQLite).
class ProdukController extends BaseController {
  /// Data asli dari database — JANGAN ditimpa oleh filter.
  List<ProductModel> _allProducts = [];

  /// Hasil filter yang ditampilkan di UI.
  List<ProductModel> _filtered = [];

  List<Category> _categories = [];
  String _query = '';
  String? _selectedCategory;
  String _filter = 'Semua'; // Semua | Tersedia | Stok Rendah | Habis

  /// Gunakan ini di UI (sudah terfilter).
  List<ProductModel> get products => _filtered;
  List<Category> get categories => _categories;
  String get query => _query;
  String? get selectedCategory => _selectedCategory;
  String get filter => _filter;

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      _categories = await (db.select(db.categories)
            ..where((c) => c.type.equals('product'))
            ..orderBy([(c) => OrderingTerm(expression: c.name)]))
          .get();
      await _loadAllProducts();
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadAllProducts() async {
    final db = DB.instance;
    final rows = await (db.select(db.products)
          ..orderBy([(p) => OrderingTerm(expression: p.name)]))
        .get();
    final catMap = {for (final c in _categories) c.id: c.name};
    // Simpan ke _allProducts — ini tidak pernah ditimpa filter
    _allProducts = rows
        .map((r) => ProductModel.fromRow(r,
            categoryName: catMap[r.categoryId] ?? 'Umum'))
        .toList();
    _applyFilters();
  }

  void setQuery(String q) {
    _query = q;
    _applyFilters();
  }

  void setSelectedCategory(String? c) {
    _selectedCategory = c;
    _applyFilters();
  }

  void setFilter(String f) {
    _filter = f;
    _applyFilters();
  }

  /// Filter dari _allProducts ke _filtered. Tidak pernah memodifikasi _allProducts.
  void _applyFilters() {
    _filtered = _allProducts.where((p) {
      final matchQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase());
      final matchCat =
          _selectedCategory == null || p.categoryName == _selectedCategory;
      bool matchFilter = true;
      switch (_filter) {
        case 'Tersedia':
          matchFilter = !p.isOutOfStock && !p.isLowStock;
          break;
        case 'Stok Rendah':
          matchFilter = p.isLowStock && !p.isOutOfStock;
          break;
        case 'Habis':
          matchFilter = p.isOutOfStock;
          break;
      }
      return matchQuery && matchCat && matchFilter;
    }).toList();
    notifyListeners();
  }

  Future<void> addProduct(ProductModel p) async {
    final db = DB.instance;
    await db.into(db.products).insert(p.toCompanion());
    await _loadAllProducts();
  }

  Future<void> updateProduct(ProductModel p) async {
    final db = DB.instance;
    await (db.update(db.products)..where((t) => t.id.equals(p.id!)))
        .write(p.toCompanion());
    await _loadAllProducts();
  }

  Future<void> deleteProduct(int id) async {
    final db = DB.instance;
    await (db.delete(db.products)..where((t) => t.id.equals(id))).go();
    await _loadAllProducts();
  }

  // --- Kategori dinamis ---
  Future<void> addCategory(String name) async {
    final db = DB.instance;
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: name, type: Value('product')),
        );
    await load();
  }

  Future<void> renameCategory(int id, String newName) async {
    final db = DB.instance;
    await (db.update(db.categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(name: Value(newName)));
    await load();
  }

  Future<void> deleteCategory(int id) async {
    final db = DB.instance;
    await (db.delete(db.categories)..where((c) => c.id.equals(id))).go();
    await (db.update(db.products)..where((t) => t.categoryId.equals(id)))
        .write(const ProductsCompanion(categoryId: Value(null)));
    await load();
  }
}
