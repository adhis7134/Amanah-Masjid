<?php
// backend/kas.php - Buku Kas Digital Real-time & Transparansi Jamaah
require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $masjidId = isset($_GET['masjid_id']) ? (int)$_GET['masjid_id'] : 1;

    // Hitung ringkasan saldo
    $stmtMasuk = $pdo->prepare("SELECT COALESCE(SUM(nominal), 0) AS total_masuk FROM transaksi_kas WHERE masjid_id = ? AND tipe = 'masuk'");
    $stmtMasuk->execute([$masjidId]);
    $totalMasuk = (float)$stmtMasuk->fetch()['total_masuk'];

    $stmtKeluar = $pdo->prepare("SELECT COALESCE(SUM(nominal), 0) AS total_keluar FROM transaksi_kas WHERE masjid_id = ? AND tipe = 'keluar'");
    $stmtKeluar->execute([$masjidId]);
    $totalKeluar = (float)$stmtKeluar->fetch()['total_keluar'];

    $saldo = $totalMasuk - $totalKeluar;

    // Ambil daftar riwayat kas
    $stmtItems = $pdo->prepare("SELECT * FROM transaksi_kas WHERE masjid_id = ? ORDER BY tanggal DESC, id DESC LIMIT 50");
    $stmtItems->execute([$masjidId]);
    $items = $stmtItems->fetchAll();

    echo json_encode([
        "status" => true,
        "summary" => [
            "total_masuk" => $totalMasuk,
            "total_keluar" => $totalKeluar,
            "saldo" => $saldo
        ],
        "data" => $items
    ]);

} elseif ($method === 'POST') {
    // Tambah Transaksi Kas oleh DKM
    $input = json_decode(file_get_contents('php://input'), true);
    $masjidId = (int)($input['masjid_id'] ?? 1);
    $tipe = $input['tipe'] ?? 'masuk'; // 'masuk' atau 'keluar'
    $nominal = (float)($input['nominal'] ?? 0);
    $kategori = trim($input['kategori'] ?? 'Kotak Amal');
    $keterangan = trim($input['keterangan'] ?? '');
    $tanggal = $input['tanggal'] ?? date('Y-m-d');
    $userId = !empty($input['user_id']) ? (int)$input['user_id'] : null;

    if ($nominal <= 0 || empty($keterangan)) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "Nominal dan keterangan harus diisi dengan benar."]);
        exit();
    }

    $stmt = $pdo->prepare("INSERT INTO transaksi_kas (masjid_id, tipe, nominal, kategori, keterangan, tanggal, created_by) 
                           VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$masjidId, $tipe, $nominal, $kategori, $keterangan, $tanggal, $userId]);

    echo json_encode([
        "status" => true,
        "message" => "Transaksi kas berhasil dicatat & disinkronisasi ke Jamaah.",
        "id" => $pdo->lastInsertId()
    ]);
}
