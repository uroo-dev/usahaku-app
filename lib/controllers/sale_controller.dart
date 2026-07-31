import 'package:drift/drift.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/database/db.dart';
import 'package:usahaku/models/customer_model.dart';
import 'package:usahaku/models/product_model.dart';
import 'package:usahaku/models/sale_model.dart';
import 'package:usahaku/utils/format_util.dart';

import 'base_controller.dart';

/// Item keranjang sementara (belum disimpan).
class CartItem {
  final ProductModel product;
  int quantity;
  CartItem(this.product, this.quantity);

  double get subtotal => product.sellPrice * quantity;
}

/// Penjualan POS: cari produk, keranjang, diskon, checkout.
class SaleController extends BaseController {
  final List<CartItem> cart = [];
  List<ProductModel> _products = [];
  List<Category> _categories = [];
  String _query = '';
  String? _selectedCategory;
  CustomerModel? selectedCustomer;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  double _discount = 0;
  String notes = '';
  String? _qrisPath;

  List<ProductModel> get products => _products;
  List<Category> get categories => _categories;
  String get query => _query;
  String? get selectedCategory => _selectedCategory;
  PaymentMethod get paymentMethod => _paymentMethod;
  double get discount => _discount;
  String? get qrisPath => _qrisPath;

  double get subtotal => cart.fold(0, (s, i) => s + i.subtotal);
  double get total => (subtotal - _discount).clamp(0, double.infinity);
  int get itemCount => cart.fold(0, (s, i) => s + i.quantity);

  Future<void> load() async {
    setLoading(true);
    try {
      final db = DB.instance;
      _categories = await (db.select(db.categories)
            ..where((c) => c.type.equals('product')))
          .get();
      final catMap = {for (final c in _categories) c.id: c.name};
      final productRows = await db.select(db.products).get();
      _products = productRows
          .map((r) => ProductModel.fromRow(r, categoryName: catMap[r.categoryId] ?? 'Umum'))
          .toList();
      final profile = await db.select(db.businessProfiles).getSingleOrNull();
      _qrisPath = profile?.qrisImagePath;
      _applyFilter();
      setError(null);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void setQuery(String q) {
    _query = q;
    _applyFilter();
    notifyListeners();
  }

  void setCategory(String? c) {
    _selectedCategory = c;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    // reload produk sesuai filter
    final list = _products.where((p) {
      final matchQuery = _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase()) || p.barcode.contains(_query);
      final matchCat = _selectedCategory == null || p.categoryName == _selectedCategory;
      return matchQuery && matchCat;
    }).toList();
    _filtered = list;
  }

  List<ProductModel> _filtered = [];
  List<ProductModel> get filteredProducts => _filtered;

  void addToCart(ProductModel p) {
    final existing = cart.where((c) => c.product.id == p.id).firstOrNull;
    if (existing != null) {
      if (existing.quantity < p.stock) existing.quantity++;
    } else {
      if (p.stock > 0) cart.add(CartItem(p, 1));
    }
    notifyListeners();
  }

  void increment(int productId) {
    final item = cart.where((c) => c.product.id == productId).firstOrNull;
    if (item != null && item.quantity < item.product.stock) item.quantity++;
    notifyListeners();
  }

  void decrement(int productId) {
    final item = cart.where((c) => c.product.id == productId).firstOrNull;
    if (item != null) {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cart.remove(item);
      }
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value.clamp(0, subtotal);
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod m) {
    _paymentMethod = m;
    notifyListeners();
  }

  void setCustomer(CustomerModel? c) {
    selectedCustomer = c;
    notifyListeners();
  }

  /// Simpan penjualan + kurangi stok + catat transaksi kas.
  Future<SaleModel> checkout() async {
    final db = DB.instance;
    final now = DateTime.now();
    final seq = await _nextSeq(db, now);
    final invoiceNo = FormatUtil.invoice(now, seq);
    final customerId = selectedCustomer?.id;

    final saleId = await db.transaction(() async {
      final saleId = await db.into(db.sales).insert(
            SalesCompanion.insert(
              invoiceNo: invoiceNo,
              customerId: Value(customerId),
              subtotal: Value(subtotal),
              discount: Value(_discount),
              total: Value(total),
              paymentMethod: Value(_paymentMethod),
              notes: Value(notes.isEmpty ? null : notes),
              date: Value(now),
            ),
          );

      for (final item in cart) {
        await db.into(db.saleItems).insert(
              SaleItemsCompanion.insert(
                saleId: saleId,
                productId: item.product.id!,
                quantity: item.quantity,
                price: Value(item.product.sellPrice),
                total: Value(item.subtotal),
              ),
            );
        final newStock = item.product.stock - item.quantity;
        await (db.update(db.products)..where((p) => p.id.equals(item.product.id!)))
            .write(ProductsCompanion(
              stock: Value(newStock < 0 ? 0 : newStock),
            ));
      }

      // Catat transaksi kas (income)
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: TransactionType.income,
              amount: Value(total),
              description: 'Penjualan $invoiceNo',
              date: Value(now),
              paymentMethod: Value(_paymentMethod),
              customerId: Value(customerId),
            ),
          );

      // Jika metode = debt, buat piutang
      if (_paymentMethod == PaymentMethod.debt) {
        final customer = await db.select(db.customers).getSingleOrNull();
        final relatedId = selectedCustomer?.id ?? customer?.id ?? await _ensureGeneralCustomer(db);
        await db.into(db.debts).insert(
              DebtsCompanion.insert(
                type: DebtType.piutang,
                relatedId: relatedId,
                amount: Value(total),
                dueDate: now.add(const Duration(days: 30)),
                description: Value('Piutang dari $invoiceNo'),
              ),
            );
      }

      return saleId;
    });

    final result = SaleModel(
      id: saleId,
      invoiceNo: invoiceNo,
      customerId: customerId,
      customerName: selectedCustomer?.name ?? defaultCustomerName,
      subtotal: subtotal,
      discount: _discount,
      total: total,
      paymentMethod: _paymentMethod,
      notes: notes,
      date: now,
      items: cart.map((c) => SaleItemModel(
            productId: c.product.id!,
            productName: c.product.name,
            quantity: c.quantity,
            price: c.product.sellPrice,
            total: c.subtotal,
          )).toList(),
    );
    cart.clear();
    _discount = 0;
    notes = '';
    selectedCustomer = null;
    notifyListeners();
    return result;
  }

  Future<int> _ensureGeneralCustomer(AppDatabase db) async {
    final existing = await (db.select(db.customers)..where((c) => c.name.equals(defaultCustomerName))).getSingleOrNull();
    if (existing != null) return existing.id;
    return db.into(db.customers).insert(CustomersCompanion.insert(name: defaultCustomerName));
  }

  Future<int> _nextSeq(AppDatabase db, DateTime d) async {
    final dayStart = DateTime(d.year, d.month, d.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final count = await (db.selectOnly(db.sales)
          ..addColumns([db.sales.id.count()])
          ..where(db.sales.date.isBiggerOrEqualValue(dayStart) & db.sales.date.isSmallerThanValue(dayEnd)))
        .getSingle();
    return count.read(db.sales.id.count())! + 1;
  }
}
