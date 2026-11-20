# Panduan Pengembangan & Arsitektur AmanahMasjid

Aplikasi **AmanahMasjid** mengintegrasikan dua pilar utama:
1. **Sistem Multi-Role** (Jamaah vs Pengurus DKM) dengan desain kontras tinggi ramah lansia.
2. **Pengingat Ibadah & Rute Perjalanan Traveler (Musafir)** dengan arsitektur hemat biaya Google Maps Platform.

Direktori proyek:
`C:\Users\MyBook Hype AMD\.gemini\antigravity\scratch\amanah_masjid`

---

## 1. Skema Database Relasional (`amanah_masjid_db`)
File SQL: [backend/database.sql](file:///C:/Users/MyBook%20Hype%20AMD/.gemini/antigravity/scratch/amanah_masjid/backend/database.sql)

- **`masjid`**: Menyimpan profil, alamat, koordinat GPS (lat, lng), dan kontak pengurus.
- **`users`**: Multi-role (`jamaah` vs `dkm`), foreign key ke `masjid_id` (kelolaan DKM) dan `masjid_diikuti_id` (favorit jamaah).
- **`jadwal_kegiatan`**: Jadwal kajian rutin, petugas sholat Jumat, dan pengumuman.
- **`transaksi_kas`**: Buku kas digital real-time (tipe `masuk`/`keluar`, nominal, kategori, timestamp).

---

## 2. Fitur Multi-Role

### A. Pengguna Umum / Jamaah & Traveler
1. **Pengingat Ibadah Harian**:
   - Hitung mundur real-time menuju waktu salat berikutnya dengan teks ukuran besar (36pt) kontras tinggi.
   - Jadwal 5 waktu (Subuh, Dzuhur, Ashar, Maghrib, Isya).
2. **Eksplorasi Masjid Terdekat (Traveler Mode)**:
   - Pencarian masjid berdasarkan radius jarak GPS menggunakan formula Haversine (`jarak_km`).
   - Tombol **"Ikuti Masjid"** untuk berganti informasi masjid secara dinamis.
   - Tombol **"Rute (Peta)"** dengan **Google Maps Deep-Link** (`https://www.google.com/maps/dir/?api=1...`) untuk navigasi belokan-demi-belokan **100% GRATIS tanpa biaya API Routes**.
3. **Papan Informasi & Warta**:
   - Jadwal kajian, mubaligh/penceramah, dan petugas imam & khatib Jumat.
4. **Transparansi Kas Masjid**:
   - Halaman khusus read-only yang menampilkan total saldo kas, total pemasukan infaq, total pengeluaran operasional, serta rincian transaksi secara real-time.

### B. Pengurus Masjid (DKM)
1. **Manajemen Profil Masjid**:
   - Form perubahan nama, alamat, nomor kontak takmir, dan fasilitas transit jamaah.
2. **Kelola Jadwal Kegiatan (CRUD)**:
   - Tambah agenda kajian atau petugas jumat, ubah, dan hapus. Data langsung tersinkron ke Jamaah.
3. **Buku Kas Digital**:
   - Pencatatan pemasukan (infaq/kotak amal) dan pengeluaran.
   - Saldo langsung terhitung otomatis dan real-time tampil di aplikasi Jamaah.

---

## 3. Strategi Optimasi Google Maps & Biaya Rendah
- **Deteksi GPS**: Menggunakan paket `geolocator` untuk membaca hardware GPS lokal tanpa membebani kuota API.
- **Deep-Link Navigasi**: Navigasi diserahkan ke aplikasi bawaan Google Maps via `url_launcher` sehingga tidak memerlukan kuota berbayar Routes API.
- **Pencarian Terdekat**: Dilakukan dengan kalkulasi spherical distance pada database lokal terlebih dahulu sebelum memanggil API eksternal.

---

## 4. Cara Menjalankan

### Backend (XAMPP):
1. Aktifkan Apache & MySQL di XAMPP.
2. Buat database `amanah_masjid_db` di `http://localhost/phpmyadmin` dan import [database.sql](file:///C:/Users/MyBook%20Hype%20AMD/.gemini/antigravity/scratch/amanah_masjid/backend/database.sql).
3. Salin folder `backend` ke `C:\xampp\htdocs\amanah_masjid\backend\`.

### Frontend Flutter:
```bash
cd "C:\Users\MyBook Hype AMD\.gemini\antigravity\scratch\amanah_masjid\mobile"
flutter pub get
flutter run -d chrome # atau emulator android
```
Akun demo sudah disiapkan pada tombol cepat di layar login:
- **Akun Jamaah:** `jamaah@amanah.id` (password: `123456`)
- **Akun Pengurus DKM:** `dkm@amanah.id` (password: `123456`)
