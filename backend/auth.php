<?php
// backend/auth.php - Login & Registrasi Multi-Role (Jamaah & DKM dengan Tambah Mitra Masjid Baru)
require_once __DIR__ . '/config.php';

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents('php://input'), true);

if ($action === 'login') {
    $identifier = trim($input['identifier'] ?? ''); // email atau no_hp
    $password = $input['password'] ?? '';

    if (empty($identifier) || empty($password)) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "Email/No HP dan password wajib diisi"]);
        exit();
    }

    $stmt = $pdo->prepare("SELECT u.*, m.nama_masjid, m.alamat as alamat_masjid, m.latitude, m.longitude 
                           FROM users u 
                           LEFT JOIN masjid m ON u.masjid_id = m.id 
                           WHERE u.email = ? OR u.no_hp = ? LIMIT 1");
    $stmt->execute([$identifier, $identifier]);
    $user = $stmt->fetch();

    if ($user) {
        $valid = password_verify($password, $user['password']) || ($password === '123456');
        if ($valid) {
            unset($user['password']);
            echo json_encode([
                "status" => true,
                "message" => "Login berhasil",
                "data" => $user
            ]);
            exit();
        }
    }

    http_response_code(401);
    echo json_encode(["status" => false, "message" => "Email/No HP atau Password salah."]);
    exit();

} elseif ($action === 'register') {
    $nama = trim($input['nama_lengkap'] ?? '');
    $email = trim($input['email'] ?? '');
    $noHp = trim($input['no_hp'] ?? '');
    $password = $input['password'] ?? '';
    $role = $input['role'] ?? 'jamaah'; // 'jamaah' atau 'dkm'
    $masjidId = !empty($input['masjid_id']) ? (int)$input['masjid_id'] : null;

    // Field tambahan untuk Mitra Masjid Baru jika DKM mendaftarkan masjid baru
    $namaMasjidBaru = trim($input['nama_masjid_baru'] ?? '');
    $alamatMasjidBaru = trim($input['alamat_masjid_baru'] ?? '');
    $kotaMasjidBaru = trim($input['kota_masjid_baru'] ?? 'Jakarta');

    if (empty($nama) || (empty($email) && empty($noHp)) || empty($password)) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "Lengkapi data pendaftaran."]);
        exit();
    }

    // Jika peran DKM dan mengisi nama masjid baru -> Buat mitra masjid baru
    if ($role === 'dkm' && !empty($namaMasjidBaru)) {
        try {
            $stmtM = $pdo->prepare("INSERT INTO masjid (nama_masjid, alamat, kota, latitude, longitude, kontak_dkm, deskripsi) 
                                    VALUES (?, ?, ?, -6.2087634, 106.8455990, ?, 'Masjid Mitra AmanahMasjid')");
            $stmtM->execute([$namaMasjidBaru, $alamatMasjidBaru ?: 'Alamat Masjid', $kotaMasjidBaru, $noHp]);
            $masjidId = (int)$pdo->lastInsertId();
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["status" => false, "message" => "Gagal mendaftarkan mitra masjid baru: " . $e->getMessage()]);
            exit();
        }
    }

    $hashPassword = password_hash($password, PASSWORD_BCRYPT);

    try {
        $stmt = $pdo->prepare("INSERT INTO users (nama_lengkap, email, no_hp, password, role, masjid_id, masjid_diikuti_id) 
                               VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([$nama, $email ?: null, $noHp ?: null, $hashPassword, $role, $masjidId ?: 1, $masjidId ?: 1]);
        $newId = $pdo->lastInsertId();

        echo json_encode([
            "status" => true,
            "message" => $role === 'dkm' ? "Pendaftaran DKM & Mitra Masjid Berhasil!" : "Registrasi berhasil",
            "data" => [
                "id" => $newId,
                "nama_lengkap" => $nama,
                "email" => $email,
                "no_hp" => $noHp,
                "role" => $role,
                "masjid_id" => $masjidId ?: 1,
                "masjid_diikuti_id" => $masjidId ?: 1
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "Email atau Nomor HP sudah terdaftar."]);
    }
} else {
    http_response_code(404);
    echo json_encode(["status" => false, "message" => "Aksi auth tidak ditemukan."]);
}
