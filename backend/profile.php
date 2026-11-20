<?php
// backend/profile.php - Ambil & Update Profil Akun (Jamaah & DKM)
require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    if ($userId <= 0) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "User ID diperlukan."]);
        exit();
    }

    $stmt = $pdo->prepare("SELECT u.id, u.nama_lengkap, u.email, u.no_hp, u.role, u.masjid_id, u.masjid_diikuti_id,
                                  m.nama_masjid, m.alamat as alamat_masjid,
                                  m2.nama_masjid as nama_masjid_diikuti
                           FROM users u
                           LEFT JOIN masjid m ON u.masjid_id = m.id
                           LEFT JOIN masjid m2 ON u.masjid_diikuti_id = m2.id
                           WHERE u.id = ? LIMIT 1");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if ($user) {
        echo json_encode(["status" => true, "data" => $user]);
    } else {
        http_response_code(404);
        echo json_encode(["status" => false, "message" => "Pengguna tidak ditemukan."]);
    }
} elseif ($method === 'PUT') {
    // Update data profil atau ganti password
    $input = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($input['user_id'] ?? 0);
    $nama = trim($input['nama_lengkap'] ?? '');
    $noHp = trim($input['no_hp'] ?? '');
    $email = trim($input['email'] ?? '');
    $passwordBaru = trim($input['password_baru'] ?? '');

    if ($userId <= 0 || empty($nama)) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "Data tidak lengkap."]);
        exit();
    }

    if (!empty($passwordBaru)) {
        $hashPassword = password_hash($passwordBaru, PASSWORD_BCRYPT);
        $stmt = $pdo->prepare("UPDATE users SET nama_lengkap = ?, no_hp = ?, email = ?, password = ? WHERE id = ?");
        $stmt->execute([$nama, $noHp, $email, $hashPassword, $userId]);
    } else {
        $stmt = $pdo->prepare("UPDATE users SET nama_lengkap = ?, no_hp = ?, email = ? WHERE id = ?");
        $stmt->execute([$nama, $noHp, $email, $userId]);
    }

    echo json_encode([
        "status" => true,
        "message" => "Profil akun berhasil diperbarui."
    ]);
}
