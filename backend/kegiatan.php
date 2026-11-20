<?php
// backend/kegiatan.php - CRUD Jadwal Kegiatan & Pengumuman
require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $masjidId = isset($_GET['masjid_id']) ? (int)$_GET['masjid_id'] : 1;
    $stmt = $pdo->prepare("SELECT * FROM jadwal_kegiatan WHERE masjid_id = ? ORDER BY tanggal ASC, waktu ASC");
    $stmt->execute([$masjidId]);
    echo json_encode(["status" => true, "data" => $stmt->fetchAll()]);

} elseif ($method === 'POST') {
    // Tambah Kegiatan oleh DKM
    $input = json_decode(file_get_contents('php://input'), true);
    $masjidId = (int)($input['masjid_id'] ?? 1);
    $judul = trim($input['judul'] ?? '');
    $penceramah = trim($input['penceramah'] ?? '');
    $tanggal = $input['tanggal'] ?? date('Y-m-d');
    $waktu = $input['waktu'] ?? '18:30:00';
    $tempat = trim($input['tempat'] ?? 'Masjid');
    $kategori = $input['kategori'] ?? 'kajian';
    $deskripsi = trim($input['deskripsi'] ?? '');

    if (empty($judul)) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "Judul kegiatan wajib diisi."]);
        exit();
    }

    $stmt = $pdo->prepare("INSERT INTO jadwal_kegiatan (masjid_id, judul, penceramah, tanggal, waktu, tempat, kategori, deskripsi) 
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$masjidId, $judul, $penceramah, $tanggal, $waktu, $tempat, $kategori, $deskripsi]);

    echo json_encode(["status" => true, "message" => "Kegiatan berhasil ditambahkan.", "id" => $pdo->lastInsertId()]);

} elseif ($method === 'PUT') {
    // Edit Kegiatan oleh DKM
    $input = json_decode(file_get_contents('php://input'), true);
    $id = (int)($input['id'] ?? 0);
    $judul = trim($input['judul'] ?? '');
    $penceramah = trim($input['penceramah'] ?? '');
    $tanggal = $input['tanggal'] ?? date('Y-m-d');
    $waktu = $input['waktu'] ?? '18:30:00';
    $tempat = trim($input['tempat'] ?? 'Masjid');
    $kategori = $input['kategori'] ?? 'kajian';
    $deskripsi = trim($input['deskripsi'] ?? '');

    $stmt = $pdo->prepare("UPDATE jadwal_kegiatan SET judul=?, penceramah=?, tanggal=?, waktu=?, tempat=?, kategori=?, deskripsi=? WHERE id=?");
    $stmt->execute([$judul, $penceramah, $tanggal, $waktu, $tempat, $kategori, $deskripsi, $id]);

    echo json_encode(["status" => true, "message" => "Kegiatan berhasil diubah."]);

} elseif ($method === 'DELETE') {
    // Hapus Kegiatan oleh DKM
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    $stmt = $pdo->prepare("DELETE FROM jadwal_kegiatan WHERE id = ?");
    $stmt->execute([$id]);

    echo json_encode(["status" => true, "message" => "Kegiatan berhasil dihapus."]);
}
