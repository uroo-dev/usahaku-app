import 'package:flutter/material.dart';
import 'package:usahaku/controllers/produk_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Kategori Produk — kelola kategori produk (Makanan, Minuman, dsb).
class KategoriProdukScreen extends StatefulWidget {
  const KategoriProdukScreen({super.key});

  @override
  State<KategoriProdukScreen> createState() => _KategoriProdukScreenState();
}

class _KategoriProdukScreenState extends State<KategoriProdukScreen> {
  final ProdukController _c = ProdukController();

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

  Future<void> _add() async {
    final name = await _NameDialog.show(context, title: 'Kategori Baru');
    if (name != null && name.isNotEmpty) {
      await _c.addCategory(name);
    }
  }

  Future<void> _rename(Category cat) async {
    final name = await _NameDialog.show(context, title: 'Ubah Kategori', initial: cat.name);
    if (name != null && name.isNotEmpty) {
      await _c.renameCategory(cat.id, name);
    }
  }

  Future<void> _delete(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "${cat.name}" akan dihapus. Produk di dalamnya menjadi tanpa kategori.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed == true) await _c.deleteCategory(cat.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Produk')),
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
                    child: const Icon(Icons.folder_outlined, size: 20, color: AppColor.primary),
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
                        onPressed: () => _rename(cat),
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

class _NameDialog extends StatelessWidget {
  final String title;
  final String initial;
  const _NameDialog({required this.title, this.initial = ''});

  static Future<String?> show(BuildContext context, {required String title, String initial = ''}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _NameDialog(title: title, initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: initial);
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Nama kategori'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Simpan')),
      ],
    );
  }
}
