import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:usahaku/controllers/settings_controller.dart';
import 'package:usahaku/models/settings_model.dart';
import 'package:usahaku/providers/app_settings_provider.dart';
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
  String? _logoPath;
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
    _logoPath = s.logoPath;
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

  Future<void> _pickLogoCamera() async {
    final picker = ImagePicker();
    final supported = picker.supportsImageSource(ImageSource.camera);
    if (!supported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera tidak tersedia di perangkat ini. Membuka galeri...')),
        );
      }
      return _pickLogoGallery();
    }
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 400,
      imageQuality: 90,
    );
    if (picked == null) return;
    await _saveLogo(picked.path);
  }

  Future<void> _pickLogoGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 90,
    );
    if (picked == null) return;
    await _saveLogo(picked.path);
  }

  Future<void> _saveLogo(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(sourcePath).copy(dest.path);
    if (mounted) setState(() => _logoPath = dest.path);
  }

  void _showLogoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Ubah Logo Bisnis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColor.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_outlined, color: AppColor.primary),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Ambil foto langsung'),
              onTap: () { Navigator.pop(ctx); _pickLogoCamera(); },
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColor.secondaryContainer, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_outlined, color: AppColor.secondary),
              ),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih dari foto tersimpan'),
              onTap: () { Navigator.pop(ctx); _pickLogoGallery(); },
            ),
            if (_logoPath != null)
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColor.errorContainer, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline, color: AppColor.error),
                ),
                title: const Text('Hapus Logo', style: TextStyle(color: AppColor.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _logoPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
      logoPath: _logoPath,
    ));
    if (mounted) {
      // Refresh global provider agar semua screen update nama bisnis
      AppSettingsProvider.of(context).refresh();
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
      child: Column(
        children: [
          GestureDetector(
            onTap: _showLogoSourceSheet,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColor.primaryFixed,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColor.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _logoPath != null && File(_logoPath!).existsSync()
                      ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                      : const Icon(Icons.storefront, color: AppColor.primary, size: 44),
                ),
                // Edit badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _logoPath != null ? 'Ubah Logo' : 'Tambah Logo',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.primary),
          ),
        ],
      ),
    );
  }
}
