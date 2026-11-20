-- ==========================================================
-- Database: amanah_masjid_db
-- Multi-Role: Jamaah vs Pengurus DKM + Traveler Location Support
-- ==========================================================

CREATE DATABASE IF NOT EXISTS amanah_masjid_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE amanah_masjid_db;

-- 1. TABEL MASJID (Profil, Lokasi GPS, Kontak)
CREATE TABLE IF NOT EXISTS masjid (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_masjid VARCHAR(150) NOT NULL,
    alamat TEXT NOT NULL,
    kota VARCHAR(100) DEFAULT 'Jakarta',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    kontak_dkm VARCHAR(50),
    deskripsi TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Data Awal Masjid
INSERT INTO masjid (nama_masjid, alamat, kota, latitude, longitude, kontak_dkm, deskripsi) VALUES
('Masjid Agung Al-Falah', 'Jl. Sudirman No. 12', 'Jakarta Pusat', -6.2087634, 106.8455990, '081298765432', 'Masjid ramah musafir dan lansia, dilengkapi fasilitas transit 24 jam.'),
('Masjid Baitul Ihsan', 'Jl. Thamrin No. 8', 'Jakarta Pusat', -6.1856721, 106.8234512, '081387654321', 'Pusat kajian sunnah dan pembinaan mualaf.'),
('Mushola An-Nur (Rest Area)', 'Tol Jagorawi KM 21', 'Bogor', -6.4521321, 106.8823412, '081512345678', 'Tempat sholat bersih dan nyaman bagi para musafir.');

-- 2. TABEL USERS (Multi-Role: 'jamaah' atau 'dkm')
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_lengkap VARCHAR(120) NOT NULL,
    email VARCHAR(120) UNIQUE,
    no_hp VARCHAR(30) UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('jamaah', 'dkm') NOT NULL DEFAULT 'jamaah',
    masjid_id INT NULL, -- NULL jika jamaah belum pilih atau bukan dkm, terisi id masjid jika dkm
    masjid_diikuti_id INT NULL, -- Masjid favorit yang diikuti jamaah
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (masjid_id) REFERENCES masjid(id) ON DELETE SET NULL,
    FOREIGN KEY (masjid_diikuti_id) REFERENCES masjid(id) ON DELETE SET NULL
);

-- Data Dummy User (Password default: '123456')
-- Hash MD5 atau bcrypt. Untuk kemudahan simulasi disimpan hash bcrypt sederhana/hash dummy
INSERT INTO users (nama_lengkap, email, no_hp, password, role, masjid_id, masjid_diikuti_id) VALUES
('H. Ahmad Dahlan (Pengurus)', 'dkm@amanah.id', '081200000001', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'dkm', 1, 1),
('Pak Bambang (Jamaah)', 'jamaah@amanah.id', '081200000002', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'jamaah', NULL, 1);

-- 3. TABEL JADWAL KEGIATAN & KAJIAN (CRUD DKM)
CREATE TABLE IF NOT EXISTS jadwal_kegiatan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    masjid_id INT NOT NULL,
    judul VARCHAR(200) NOT NULL,
    penceramah VARCHAR(120),
    tanggal DATE NOT NULL,
    waktu TIME NOT NULL,
    tempat VARCHAR(120) DEFAULT 'Ruang Sholat Utama',
    kategori ENUM('kajian', 'jumat', 'peringatan', 'pengumuman') DEFAULT 'kajian',
    deskripsi TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (masjid_id) REFERENCES masjid(id) ON DELETE CASCADE
);

INSERT INTO jadwal_kegiatan (masjid_id, judul, penceramah, tanggal, waktu, tempat, kategori, deskripsi) VALUES
(1, 'Kajian Shubuh: Fiqih Safar & Ibadah Musafir', 'Ust. DR. Khalid Basalamah, M.A.', CURRENT_DATE(), '05:00:00', 'Ruang Utama', 'kajian', 'Panduan sholat jamak, qashar, dan rukhshah bagi traveler.'),
(1, 'Petugas Shalat Jumat', 'Khatib: Ust. Dr. H. Salim A. Fillah | Imam: Ust. Muzammil Hasballah', DATE_ADD(CURRENT_DATE(), INTERVAL (5 - DAYOFWEEK(CURRENT_DATE()) + 7) % 7 DAY), '11:45:00', 'Masjid Utama', 'jumat', 'Himbauan datang 30 menit sebelum azan dikumandangkan.'),
(1, 'Penyediaan Sahur & Buka Puasa Sunnah Gratis', 'Sie Takmir Masjid', DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY), '17:30:00', 'Serambi Masjid', 'pengumuman', 'Dibuka untuk para musafir dan jamaah umum.');

-- 4. TABEL BUKU KAS DIGITAL (Infak, Donasi, Pengeluaran)
CREATE TABLE IF NOT EXISTS transaksi_kas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    masjid_id INT NOT NULL,
    tipe ENUM('masuk', 'keluar') NOT NULL,
    nominal DECIMAL(15, 2) NOT NULL,
    kategori VARCHAR(80) NOT NULL, -- e.g., 'Kotak Amal Jumat', 'Listrik & Air', 'Infaq Musafir'
    keterangan VARCHAR(255) NOT NULL,
    tanggal DATE NOT NULL,
    created_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (masjid_id) REFERENCES masjid(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

INSERT INTO transaksi_kas (masjid_id, tipe, nominal, kategori, keterangan, tanggal) VALUES
(1, 'masuk', 8750000.00, 'Kotak Amal Jumat', 'Infaq Jamaah Shalat Jumat Berkah', DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)),
(1, 'masuk', 2500000.00, 'Infaq Musafir / QRIS', 'Donasi QRIS Musafir & Jamaah Harian', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)),
(1, 'keluar', 1200000.00, 'Operasional & Kebersihan', 'Biaya Listrik AC & Sabun Pembersih Tempat Wudhu', CURRENT_DATE()),
(1, 'keluar', 450000.00, 'Air Minum Jamaah', 'Pengadaan 15 Galon Air Mineral Musafir', CURRENT_DATE());
