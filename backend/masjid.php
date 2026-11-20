<?php
// backend/masjid.php - Pencarian, Profil, dan Ikuti Masjid (Termasuk Formula Jarak GPS & Fasilitas)
require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $search = trim($_GET['search'] ?? '');
    $lat = isset($_GET['lat']) ? (float)$_GET['lat'] : null;
    $lng = isset($_GET['lng']) ? (float)$_GET['lng'] : null;
    $masjidId = isset($_GET['id']) ? (int)$_GET['id'] : null;

    if ($masjidId) {
        $stmt = $pdo->prepare("SELECT * FROM masjid WHERE id = ?");
        $stmt->execute([$masjidId]);
        $masjid = $stmt->fetch();
        echo json_encode(["status" => true, "data" => $masjid]);
        exit();
    }

    // Jika ada koordinat GPS, hitung jarak Haversine (km) secara optimal
    if ($lat !== null && $lng !== null) {
        $query = "SELECT *, 
                  (6371 * acos(cos(radians(:lat)) * cos(radians(latitude)) * cos(radians(longitude) - radians(:lng)) + sin(radians(:lat)) * sin(radians(latitude)))) AS jarak_km 
                  FROM masjid 
                  WHERE nama_masjid LIKE :search OR alamat LIKE :search 
                  ORDER BY jarak_km ASC LIMIT 20";
        $stmt = $pdo->prepare($query);
        $stmt->execute([
            ':lat' => $lat,
            ':lng' => $lng,
            ':search' => "%$search%"
        ]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM masjid WHERE nama_masjid LIKE ? OR alamat LIKE ? ORDER BY nama_masjid ASC LIMIT 20");
        $stmt->execute(["%$search%", "%$search%"]);
    }

    echo json_encode(["status" => true, "data" => $stmt->fetchAll()]);
} elseif ($method === 'PUT') {
    // Update profil masjid oleh DKM
    $input = json_decode(file_get_contents('php://input'), true);
    $id = (int)($input['id'] ?? 0);
    $nama = trim($input['nama_masjid'] ?? '');
    $alamat = trim($input['alamat'] ?? '');
    $kontak = trim($input['kontak_dkm'] ?? '');
    $deskripsi = trim($input['deskripsi'] ?? '');
    $fasilitas = trim($input['fasilitas'] ?? '24jam,ramah_lansia,wudhu_duduk,parkir_luas');
    $lat = (float)($input['latitude'] ?? -6.2087634);
    $lng = (float)($input['longitude'] ?? 106.8455990);

    if ($id <= 0 || empty($nama) || empty($alamat)) {
        http_response_code(400);
        echo json_encode(["status" => false, "message" => "ID, nama masjid, dan alamat wajib diisi."]);
        exit();
    }

    $stmt = $pdo->prepare("UPDATE masjid SET nama_masjid = ?, alamat = ?, kontak_dkm = ?, deskripsi = ?, fasilitas = ?, latitude = ?, longitude = ? WHERE id = ?");
    $stmt->execute([$nama, $alamat, $kontak, $deskripsi, $fasilitas, $lat, $lng, $id]);

    echo json_encode(["status" => true, "message" => "Profil masjid berhasil diperbarui."]);
}
