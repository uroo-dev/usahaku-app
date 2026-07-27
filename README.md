# UsahaKu

> Offline-first mobile app for UMKM — manage your entire business from your phone, anywhere, anytime — no internet required.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Riverpod-FF6F00?style=for-the-badge&logo=flutter&logoColor=white" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Go%20Router-0066FF?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Go Router" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## Table of Contents

- [Tentang Aplikasi](#tentang-aplikasi)
- [Masalah](#masalah)
- [Solusi](#solusi)
- [Fitur Utama](#fitur-utama)
- [Teknologi](#teknologi)
- [Arsitektur](#arsitektur)
- [Instalasi](#instalasi)
- [Roadmap](#roadmap)
- [Kontribusi](#kontribusi)
- [Lisensi](#lisensi)
- [Kontak](#kontak)

---

## Tentang Aplikasi

**UsahaKu** adalah aplikasi mobile *offline-first* yang dirancang khusus untuk membantu pelaku **UMKM** mengelola operasional usaha sehari-hari secara **mudah, rapi, dan efisien**.

Dulu, mencatat transaksi, stok, kas, serta hutang piutang dilakukan secara manual di buku atau spreadsheet — rentan kesalahan, sulit dianalisis, dan tidak efisien. UsahaKu menghadirkan solusi **digital** yang ringan, cepat, dan bisa digunakan **tanpa koneksi internet**.

---

## Masalah

| No | Masalah |
|----|---------|
| 1 | Pencatatan usaha manual rentan salah dan lambat |
| 2 | Aplikasi berbasis cloud memerlukan internet terus-menerus |
| 3 | Solusi yang ada terlalu kompleks untuk UMKM kecil |
| 4 | Biaya berlangganan memberatkan pelaku usaha |
| 5 | Tidak ada solusi all-in-one yang sederhana |

---

## Solusi

UsahaKu hadir sebagai **aplikasi lokal all-in-one** yang:

- **Offline sepenuhnya** — semua data tersimpan di perangkat (SQLite)
- **Tidak memerlukan akun atau login** — buka dan langsung gunakan
- **Cepat** — database lokal, tidak ada latensi jaringan
- **Gratis** — tidak ada biaya berlangganan
- **Ringan** — antarmuka sederhana, mudah dipelajari siapa saja
- **All-in-one** — satu aplikasi untuk semua kebutuhan usaha

---

## Fitur Utama

### Dashboard
Ringkasan kondisi usaha secara real-time: total kas, penjualan hari ini, jumlah transaksi, barang stok menipis, total piutang dan hutang.

### Barang
Kelola seluruh produk: tambah, edit, hapus, kategori, harga beli/jual, stok, minimal stok, dan pencarian.

### Transaksi
Catat penjualan dengan keranjang, diskon, pembayaran tunai dan hutang. Stok dan kas diperbarui otomatis.

### Pelanggan
Data pelanggan tetap, riwayat transaksi, dan total piutang.

### Supplier
Data supplier dan total hutang.

### Kas
Pencatatan arus kas lengkap:
  - **Masuk:** Penjualan, Modal, Pendapatan lainnya
  - **Keluar:** Belanja barang, Operasional, Gaji, Listrik, Air, BBM, Hutang dan Piutang

### Hutang dan Piutang
Kelola pembayaran yang belum lunas: daftar hutang/piutang, riwayat pembayaran, status lunas.

### Laporan
Pantau perkembangan usaha: laporan penjualan, kas, pengeluaran, barang terlaris, barang hampir habis, hutang, dan piutang.

### Kalkulator
Kalkulator sederhana inline untuk menghitung harga, diskon, keuntungan, dan total belanja tanpa keluar aplikasi. Tidak menyimpan riwayat perhitungan.

### Pengaturan
Konfigurasi usaha: nama, logo, alamat, nomor telepon, tema, mata uang.

---

## Teknologi

| Komponen | Teknologi |
|----------|-----------|
| **Platform** | Flutter (iOS, Android, Web, Desktop) |
| **Bahasa** | Dart |
| **Database Lokal** | SQLite via Drift ORM |
| **State Management** | Riverpod |
| **Navigation** | Go Router |
| **Arsitektur** | Clean Architecture |
| **Linting** | flutter_lints, analysis_options.yaml |
| **Versi** | 1.0.0+1 |

---

## Arsitektur

```
usahaku_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── network/
│   │   ├── theme/
│   │   └── utils/
│   ├── data/
│   │   ├── datasources/       # Local (SQLite/Drift)
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── providers/         # Riverpod
│       ├── routes/            # Go Router
│       ├── screens/
│       ├── widgets/
│       └── theme/
├── test/
├── android/
├── ios/
├── web/
└── windows/
```

**Prinsip:**
  - **Domain-driven** — business logic terpisah dari data dan UI
  - **Repository Pattern** — abstraksi akses data
  - **Dependency Injection** — via Riverpod Provider
  - **Testable** — setiap layer bisa diuji secara independen

---

## Instalasi

### Prasyarat

- **Flutter SDK** >= 3.12
- **Dart** >= 3.12
- **SQLite** (built-in via Drift)

### Langkah

```bash
# 1. Clone repository
git clone https://github.com/uroo-dev/usahaku-app.git

# 2. Masuk ke direktori proyek
cd usahaku-app

# 3. Install dependencies
flutter pub get

# 4. Jalankan aplikasi
flutter run
```

### Menjalankan Tests

```bash
flutter test
```

### Analisis Kode

```bash
dart analyze
```

---

## Roadmap

### Versi Saat Ini (v1.0)
- [x] Dashboard Ringkas
- [x] Manajemen Barang dan Stok
- [x] Transaksi Penjualan
- [x] Manajemen Pelanggan dan Supplier
- [x] Pencatatan Kas (Masuk dan Keluar)
- [x] Pengelolaan Hutang dan Piutang
- [x] Laporan Usaha
- [x] Kalkulator Inline
- [x] Pengaturan Usaha
- [x] Database Lokal (SQLite + Drift)
- [x] Riverpod State Management
- [x] Go Router Navigation
- [x] Clean Architecture

### Pengembangan Selanjutnya
- [ ] Sinkronisasi Cloud
- [ ] Backup Online
- [ ] Multi Perangkat
- [ ] Dashboard Web
- [ ] AI Business Assistant — analisis data dan rekomendasi bisnis

---

## Kontribusi

Kontribusi sangat kami harapkan! Silakan:

1. **Fork** repository ini
2. Buat **branch** fitur (`git checkout -b fitur/baru`)
3. Commit perubahan (`git commit -am "Tambah fitur baru"`)
4. Push ke branch (`git push origin fitur/baru`)
5. Buka **Pull Request**

---

## Lisensi

Proyek ini dilisensikan di bawah **MIT License** — lihat file [LICENSE](LICENSE) untuk detailnya.

---

## Kontak

| Platform | Link |
|----------|------|
| **GitHub** | [github.com/uroo-dev](https://github.com/uroo-dev) |
| **Repository** | [github.com/uroo-dev/usahaku-app](https://github.com/uroo-dev/usahaku-app) |

---

<p align="center">
  <b>UsahaKu</b> — <i>Karena UMKM Indonesia Layak Dicatat dengan Baik.</i> 🇮🇩
</p>
