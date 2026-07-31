import 'package:flutter/material.dart';
import 'package:usahaku/controllers/supplier_controller.dart';
import 'package:usahaku/models/supplier_model.dart';

/// Form tambah / edit supplier.
class SupplierFormScreen extends StatefulWidget {
  final SupplierModel? supplier;
  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  SupplierModel? get supplier => widget.supplier;
  bool get isEdit => supplier != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: supplier?.name ?? '');
    _phoneCtrl.text = supplier?.phone ?? '';
    _addressCtrl.text = supplier?.address ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final controller = SupplierController();
    final model = SupplierModel(
      id: supplier?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    if (isEdit) {
      await controller.update(model);
    } else {
      await controller.add(model);
    }
    controller.dispose();
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Supplier' : 'Supplier Baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(labelText: 'Nama *', hintText: 'Nama supplier'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. HP', hintText: '08xx-xxxx-xxxx'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Alamat', hintText: 'Alamat supplier (opsional)'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
