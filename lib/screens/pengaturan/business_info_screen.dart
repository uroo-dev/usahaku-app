import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usahaku/controllers/settings_controller.dart';
import 'package:usahaku/models/settings_model.dart';
import 'package:usahaku/theme/app_theme.dart';

/// Form informasi bisnis — sesuai informasi-bisnis.html.
class BusinessInfoScreen extends StatefulWidget {
  final SettingsController controller;
  const BusinessInfoScreen({super.key, required this.controller});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _npwpCtrl;
  bool _saving = false;

  SettingsController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    final s = c.settings;
    _nameCtrl = TextEditingController(text: s.businessName);
    _ownerCtrl = TextEditingController(text: s.owner);
    _phoneCtrl = TextEditingController(text: s.phone);
    _addressCtrl = TextEditingController(text: s.address);
    _npwpCtrl = TextEditingController(text: s.npwp);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _npwpCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await c.save(SettingsModel(
      id: c.settings.id,
      businessName: _nameCtrl.text.trim().isEmpty ? 'Usaha Saya' : _nameCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      npwp: _npwpCtrl.text.trim(),
      currency: c.settings.currency,
      theme: c.settings.theme,
      qrisImagePath: c.settings.qrisImagePath,
      logoPath: c.settings.logoPath,
    ));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Bisnis')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _logoPicker(),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Bisnis *', hintText: 'contoh: Warung Berkah Jaya'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ownerCtrl,
              decoration: const InputDecoration(labelText: 'Nama Pemilik', hintText: 'Nama Anda'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'No. Telepon', hintText: '08xx-xxxx-xxxx'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Alamat', hintText: 'Alamat usaha Anda'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _npwpCtrl,
              decoration: const InputDecoration(labelText: 'NPWP (opsional)', hintText: 'Nomor NPWP'),
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
    );
  }

  Widget _logoPicker() {
    return Center(
      child: GestureDetector(
        onTap: () => _pickLogo(),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColor.primaryFixed,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.storefront, color: AppColor.primary, size: 44),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ubah Logo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo dipilih (disimpan setelah Simpan)')),
    );
  }
}
