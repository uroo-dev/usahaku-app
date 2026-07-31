import 'package:flutter/material.dart';
import 'package:usahaku/controllers/unit_controller.dart';
import 'package:usahaku/database/app_database.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Satuan Produk — kelola daftar satuan (pcs, kg, liter, dsb).
class SatuanProdukScreen extends StatefulWidget {
  const SatuanProdukScreen({super.key});

  @override
  State<SatuanProdukScreen> createState() => _SatuanProdukScreenState();
}

class _SatuanProdukScreenState extends State<SatuanProdukScreen> {
  final UnitController _c = UnitController();

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
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _NameDialog(title: 'Satuan Baru'),
    );
    if (name != null && name.trim().isNotEmpty) {
      await _c.add(name.trim());
    }
  }

  Future<void> _rename(Unit u) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _NameDialog(title: 'Ubah Satuan', initial: u.name),
    );
    if (name != null && name.trim().isNotEmpty) {
      await _c.rename(u.id, name.trim());
    }
  }

  Future<void> _delete(Unit u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Satuan?'),
        content: Text('Satuan "${u.name}" akan dihapus. Produk yang memakainya tidak ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed == true) await _c.delete(u.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satuan Produk')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (_c.isLoading) return const Center(child: CircularProgressIndicator());
          if (_c.units.isEmpty) {
            return const Center(
              child: Text('Belum ada satuan. Tambahkan satuan baru.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: _c.units.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final u = _c.units[index];
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
                    child: const Icon(Icons.straighten, size: 20, color: AppColor.primary),
                  ),
                  title: Text(
                    u.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.onSurface),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColor.primary),
                        onPressed: () => _rename(u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColor.error),
                        onPressed: () => _delete(u),
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

class _NameDialog extends StatefulWidget {
  final String title;
  final String initial;
  const _NameDialog({required this.title, this.initial = ''});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Nama satuan, mis. Pcs, Kg, Liter'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Simpan')),
      ],
    );
  }
}
