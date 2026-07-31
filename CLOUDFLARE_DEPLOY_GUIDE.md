# Panduan Hosting Website UsahaKu di Cloudflare Pages

Website UsahaKu (folder `docs/`) adalah situs statis murni (HTML + Tailwind CDN + GSAP CDN), jadi paling cocok di-hosting di **Cloudflare Pages** — gratis, cepat, CDN global, dan HTTPS otomatis.

## Keuntungan Cloudflare Pages
- Gratis tanpa batas bandwidth
- SSL otomatis (https://)
- Auto-deploy dari GitHub tiap kali `main` di-push
- Bisa pakai custom domain (mis. `usahaku.id`)

---

## Cara 1: Deploy dari GitHub (otomatis, disarankan)

1. **Buat akun Cloudflare** di https://dash.cloudflare.com/sign-up (gratis).
2. Login ke dashboard → klik **Workers & Pages** (menu samping kiri).
3. Klik **Create** → tab **Pages** → **Connect to Git**.
4. Pilih GitHub → otorisasi Cloudflare mengakses repo `uroo-dev/usahaku-app`.
5. Pilih repo tersebut → klik **Begin setup**.
6. Di halaman konfigurasi build, isi:
   - **Project name:** `usahaku` (bebas)
   - **Production branch:** `main`
   - **Build command:** (kosongkan)
   - **Build output directory:** `docs`
7. Klik **Save and Deploy**.
8. Tunggu ~1 menit. Selesai! Situs live di `https://usahaku.pages.dev`.

Setelah ini, **setiap push ke `main` otomatis di-deploy ulang** oleh Cloudflare. Tidak perlu upload manual.

---

## Cara 2: Upload manual (jika tidak mau hubungkan GitHub)

1. Klik **Workers & Pages** → **Create** → **Pages** → **Upload assets**.
2. Beri nama project (mis. `usahaku`).
3. Drag & drop **isi** folder `docs/`:
   - `index.html`
   - folder `assets/`
4. Klik **Deploy site**. Selesai.

Catatan: cara ini tidak auto-update; perlu upload ulang manual setiap ada perubahan.

---

## Langkah tambahan (disarankan)

### 1. Custom domain
Kalau sudah punya domain (mis. `usahaku.id`):
1. Di project Pages → tab **Custom domains** → **Set up a custom domain**.
2. Masukkan domain, ikuti instruksi mengubah DNS di dashboard Cloudflare (atau nama server).

### 2. Alias halaman
Halaman utama bisa diakses via:
- `https://usahaku.pages.dev/`
- `https://uroo-dev.github.io/usahaku-app/` (GitHub Pages, yang aktif sekarang)

### 3. Perbarui link download
Tombol download di `index.html` **sudah** menunjuk ke GitHub Releases permanen:
`https://github.com/uroo-dev/usahaku-app/releases/latest/download/UsahaKu.apk`
Jadi di Cloudflare pun, tombolnya selalu mengunduh versi APK terbaru — tidak perlu diubah.

---

## Cara cek berhasil
Buka URL situs → pastikan:
- Halaman hero tampil dengan logo UsahaKu
- Tombol **Download** mengunduh file `UsahaKu.apk`
- Judul tab browser: `UsahaKu`
