import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:usahaku/controllers/produk_controller.dart';
import 'package:usahaku/models/product_model.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/widgets/labeled_field.dart';

/// Form Tambah / Edit Produk — sesuai produk-created-edit.html.
class AddProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late final ProdukController _c = ProdukController();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _categoryId;
  String _unit = 'pcs';
  int _stock = 0;
  int _minStock = 5;
  String? _imagePath;
  bool _saving = false;

  final List<String> _units = ['pcs', 'kg', 'box', 'liter'];

  @override
  void initState() {
    super.initState();
    _c.load();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name;
      _barcodeCtrl.text = p.barcode;
      _purchaseCtrl.text = p.purchasePrice.toStringAsFixed(0);
      _sellCtrl.text = p.sellPrice.toStringAsFixed(0);
      _descCtrl.text = p.description ?? '';
      _categoryId = p.categoryId;
      _unit = p.unit;
      _stock = p.stock;
      _minStock = p.minStock;
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchaseCtrl.dispose();
    _sellCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/product_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(picked.path).copy(file.path);
    setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showMsg('Nama produk wajib diisi');
      return;
    }
    setState(() => _saving = true);
    try {
      final product = ProductModel(
        id: widget.product?.id,
        name: _nameCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim(),
        categoryId: _categoryId,
        purchasePrice: double.tryParse(_purchaseCtrl.text) ?? 0,
        sellPrice: double.tryParse(_sellCtrl.text) ?? 0,
        stock: _stock,
        minStock: _minStock,
        unit: _unit,
        imagePath: _imagePath,
        description: _descCtrl.text.trim(),
      );
      if (widget.product == null) {
        await _c.addProduct(product);
      } else {
        await _c.updateProduct(product);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMsg(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              _imageSection(),
              const SizedBox(height: 24),
              LabeledField(
                label: 'Barcode / SKU',
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Scan atau ketik kode',
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColor.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: AppColor.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Nama Produk',
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Contoh: Kopi Susu Gula Aren'),
                ),
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Kategori',
                child: _categoryDropdown(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: LabeledField(
                      label: 'Harga Modal',
                      child: TextField(
                        controller: _purchaseCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(prefixText: 'Rp '),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: 'Harga Jual',
                      child: TextField(
                        controller: _sellCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(prefixText: 'Rp '),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: LabeledField(label: 'Stok Saat Ini', child: StepperField(value: _stock, onChanged: (v) => setState(() => _stock = v))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(label: 'Stok Minimum', child: StepperField(value: _minStock, onChanged: (v) => setState(() => _minStock = v))),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Satuan',
                child: _unitDropdown(),
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Deskripsi',
                child: TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Ceritakan detail produk Anda...', alignLabelWithHint: true),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: AppColor.surface.withValues(alpha: 0.9),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: Icon(_saving ? Icons.hourglass_top : Icons.save_outlined, size: 20),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan Produk'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: _imagePath != null
                ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColor.primaryContainer, shape: BoxShape.circle),
                        child: const Icon(Icons.add_a_photo, color: AppColor.primary, size: 26),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Foto Produk',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Ambil Foto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<int?>(
      initialValue: _categoryId,
      isExpanded: true,
      decoration: const InputDecoration(hintText: 'Pilih Kategori'),
      items: [
        ..._c.categories.map((cat) => DropdownMenuItem<int?>(value: cat.id, child: Text(cat.name))),
        const DropdownMenuItem<int?>(value: null, child: Text('+ Tambah Baru')),
      ],
      onChanged: (v) {
        if (v == null) {
          _addNewCategory(context);
        } else {
          setState(() => _categoryId = v);
        }
      },
    );
  }

  Future<void> _addNewCategory(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _CategoryNameDialog(title: 'Kategori Baru'),
    );
    if (name != null && name.isNotEmpty) {
      await _c.addCategory(name);
      final fresh = _c.categories.firstWhere((cat) => cat.name == name, orElse: () => _c.categories.first);
      setState(() => _categoryId = fresh.id);
    }
  }

  Widget _unitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _unit,
      isExpanded: true,
      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(_unitLabel(u)))).toList(),
      onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
    );
  }

  String _unitLabel(String u) {
    switch (u) {
      case 'pcs':
        return 'Pcs (Biji)';
      case 'kg':
        return 'Kg (Kilogram)';
      case 'box':
        return 'Box (Kotak)';
      case 'liter':
        return 'Liter';
    }
    return u;
  }
}

class _CategoryNameDialog extends StatelessWidget {
  final String title;
  const _CategoryNameDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
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

/// Bottom sheet pilih kategori untuk filter produk (dipakai produk_screen).
Future<void> showCategorySheet(BuildContext context, ProdukController c) async {
  await showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Pilih Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                ListTile(
                  leading: const Icon(Icons.all_inbox_outlined),
                  title: const Text('Semua'),
                  onTap: () {
                    c.setSelectedCategory(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...c.categories.map((cat) => ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(cat.name),
                      onTap: () {
                        c.setSelectedCategory(cat.name);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            );
          },
        ),
      );
    },
  );
}
