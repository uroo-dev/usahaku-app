import 'package:flutter/material.dart';
import 'package:usahaku/controllers/cash_controller.dart';
import 'package:usahaku/models/cash_transaction_model.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Kategori Kas — kelola kategori pemasukan/pengeluaran dengan ikon.
class KategoriKasScreen extends StatefulWidget {
  const KategoriKasScreen({super.key});

  @override
  State<KategoriKasScreen> createState() => _KategoriKasScreenState();
}

class _KategoriKasScreenState extends State<KategoriKasScreen> {
  final CashController _c = CashController();

  static const List<(String, IconData)> _iconOptions = [
    ('point_of_sale', Icons.point_of_sale),
    ('storefront', Icons.storefront),
    ('shopping_cart', Icons.shopping_cart),
    ('receipt_long', Icons.receipt_long),
    ('payments', Icons.payments_outlined),
    ('savings', Icons.savings),
    ('account_balance', Icons.account_balance),
    ('trending_up', Icons.trending_up),
    ('trending_down', Icons.trending_down),
    ('work', Icons.work_outline),
    ('home', Icons.home_outlined),
    ('restaurant', Icons.restaurant),
    ('directions_car', Icons.directions_car),
    ('school', Icons.school_outlined),
    ('health_and_safety', Icons.health_and_safety_outlined),
    ('category', Icons.category_outlined),
    ('label', Icons.label_outline),
  ];

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

  IconData _iconOf(String name) {
    for (final (key, icon) in _iconOptions) {
      if (key == name) return icon;
    }
    return Icons.label_outline;
  }

  Future<void> _add() async {
    final result = await _CategoryDialog.show(context, iconOptions: _iconOptions);
    if (result == null) return;
    await _c.addCategory(result.$1, result.$2);
  }

  Future<void> _edit(CashCategoryModel cat) async {
    final result = await _CategoryDialog.show(
      context,
      iconOptions: _iconOptions,
      initialName: cat.name,
      initialIcon: cat.icon,
    );
    if (result == null) return;
    if (result.$1 != cat.name) await _c.renameCategory(cat.id!, result.$1);
    if (result.$2 != cat.icon) await _c.updateCategoryIcon(cat.id!, result.$2);
  }

  Future<void> _delete(CashCategoryModel cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "${cat.name}" akan dihapus. Transaksi lama tetap ada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed == true) await _c.deleteCategory(cat.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Kas')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (_c.isLoading) return const Center(child: CircularProgressIndicator());
          if (_c.categories.isEmpty) {
            return const Center(child: Text('Belum ada kategori. Tambahkan kategori baru.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: _c.categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cat = _c.categories[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColor.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColor.primaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconOf(cat.icon), size: 20, color: AppColor.primary),
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.onSurface),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColor.primary),
                        onPressed: () => _edit(cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColor.error),
                        onPressed: () => _delete(cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final List<(String, IconData)> iconOptions;
  final String initialName;
  final String initialIcon;
  const _CategoryDialog({
    required this.iconOptions,
    this.initialName = '',
    this.initialIcon = 'label',
  });

  static Future<(String, String)?> show(
    BuildContext context, {
    required List<(String, IconData)> iconOptions,
    String initialName = '',
    String initialIcon = 'label',
  }) {
    return showDialog<(String, String)>(
      context: context,
      builder: (ctx) => _CategoryDialog(
        iconOptions: iconOptions,
        initialName: initialName,
        initialIcon: initialIcon,
      ),
    );
  }

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initialName);
  late String _icon = widget.initialIcon;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kategori Kas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nama kategori, mis. Transport'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.iconOptions.map((opt) {
              final (key, icon) = opt;
              final selected = _icon == key;
              return InkWell(
                onTap: () => setState(() => _icon = key),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? AppColor.primary : AppColor.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? AppColor.primary : AppColor.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, size: 20, color: selected ? Colors.white : AppColor.onSurfaceVariant),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_ctrl.text.trim(), _icon)),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
