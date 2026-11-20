<?php
// backend/jadwal_sholat.php
// Menghitung / Menyediakan Jadwal Salat Dinamis Otomatis Berdasarkan Koordinat GPS Pengguna (WIB / Waktu Lokal)
require_once __DIR__ . '/config.php';

date_default_timezone_set('Asia/Jakarta');

$lat = isset($_GET['lat']) ? (float)$_GET['lat'] : -6.2088; // Default Jakarta
$lng = isset($_GET['lng']) ? (float)$_GET['lng'] : 106.8456;
$tgl = $_GET['tanggal'] ?? date('Y-m-d');

// Rumus Aproksimasi Astronomis Waktu Shalat
$dateObj = new DateTime($tgl);
$dayOfYear = (int)$dateObj->format('z') + 1;

// Sudut deklinasi matahari (deklinasi surya)
$d = 2 * M_PI * ($dayOfYear - 1) / 365.0;
$decl = 0.006918 - 0.399912 * cos($d) + 0.070257 * sin($d) - 0.006758 * cos(2 * $d) + 0.000907 * sin(2 * $d);

// Persamaan waktu (Equation of Time dalam menit)
$eqt = 229.18 * (0.000075 + 0.001868 * cos($d) - 0.032077 * sin($d) - 0.014615 * cos(2 * $d) - 0.040849 * sin(2 * $d));

// Waktu Transit Matahari / Dzuhur (UTC+7)
$timezoneOffset = 7.0; // WIB
$solarNoon = 12 + $timezoneOffset - ($lng / 15.0) - ($eqt / 60.0);

// Sudut elevasi matahari (Kemenag RI: Subuh = -20°, Isya = -18°)
function calculateHourAngle($lat, $decl, $angle) {
    $latRad = deg2rad($lat);
    $val = (sin(deg2rad($angle)) - sin($latRad) * sin($decl)) / (cos($latRad) * cos($decl));
    if ($val > 1) return 0;
    if ($val < -1) return M_PI;
    return acos($val);
}

// Subuh (-20 derajat)
$haFajr = rad2deg(calculateHourAngle($lat, $decl, -20.0)) / 15.0;
$subuhHour = $solarNoon - $haFajr;

// Terbit / Syuruq (-0.833 derajat)
$haSunrise = rad2deg(calculateHourAngle($lat, $decl, -0.833)) / 15.0;
$terbitHour = $solarNoon - $haSunrise;

// Dzuhur (tambah ikhtiyath 2 menit)
$dzuhurHour = $solarNoon + (2.0 / 60.0);

// Ashar (Bayangan = 1 + tan(lat - decl))
$latRad = deg2rad($lat);
$asrAlt = rad2deg(atan(1.0 / (1.0 + tan(abs($latRad - $decl)))));
$haAsr = rad2deg(calculateHourAngle($lat, $decl, $asrAlt)) / 15.0;
$asharHour = $solarNoon + $haAsr;

// Maghrib (-0.833 derajat + ikhtiyath 2 menit)
$maghribHour = $solarNoon + $haSunrise + (2.0 / 60.0);

// Isya (-18 derajat)
$haIsha = rad2deg(calculateHourAngle($lat, $decl, -18.0)) / 15.0;
$isyaHour = $solarNoon + $haIsha;

function formatJam($decimalHours) {
    $hours = floor($decimalHours);
    $minutes = floor(($decimalHours - $hours) * 60);
    return sprintf("%02d:%02d", $hours, $minutes);
}

$jadwal = [
    "subuh" => formatJam($subuhHour),
    "terbit" => formatJam($terbitHour),
    "dzuhur" => formatJam($dzuhurHour),
    "ashar" => formatJam($asharHour),
    "maghrib" => formatJam($maghribHour),
    "isya" => formatJam($isyaHour),
    "timezone" => "WIB (UTC+7)",
    "lokasi" => [
        "latitude" => $lat,
        "longitude" => $lng
    ]
];

echo json_encode([
    "status" => true,
    "tanggal" => $tgl,
    "data" => $jadwal
]);
