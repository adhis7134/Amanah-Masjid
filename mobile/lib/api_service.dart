import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Endpoint Backend di XAMPP htdocs:
  static const String baseUrl = 'http://localhost/amanah_masjid';

  // Jadwal Sholat Dinamis Sesuai Koordinat GPS & Zona Waktu Lokal
  static Future<Map<String, dynamic>?> getJadwalSholat({double? lat, double? lng}) async {
    try {
      String url = '$baseUrl/jadwal_sholat.php';
      if (lat != null && lng != null) {
        url += '?lat=$lat&lng=$lng';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['data'];
      }
    } catch (_) {}
    return null;
  }

  // 1. Auth Multi-Role & Manajemen Akun
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth.php?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': identifier, 'password': password}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'status': false, 'message': 'Gagal terhubung ke server backend: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/profile.php?user_id=$userId'));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (_) {}
    return {'status': false, 'message': 'Gagal memuat profil'};
  }

  static Future<bool> updateProfile(Map<String, dynamic> payload) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      final data = json.decode(res.body);
      return data['status'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String role,
    int? masjidId,
    String? namaMasjidBaru,
    String? alamatMasjidBaru,
    String? kotaMasjidBaru,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth.php?action=register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama_lengkap': nama,
          'email': email,
          'no_hp': noHp,
          'password': password,
          'role': role,
          'masjid_id': masjidId,
          'nama_masjid_baru': namaMasjidBaru,
          'alamat_masjid_baru': alamatMasjidBaru,
          'kota_masjid_baru': kotaMasjidBaru,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'status': false, 'message': 'Gagal mendaftar: $e'};
    }
  }

  // 2. Eksplorasi Masjid & Lokasi GPS Musafir
  static Future<List<dynamic>> searchMasjid({String query = '', double? lat, double? lng}) async {
    try {
      String url = '$baseUrl/masjid.php?search=$query';
      if (lat != null && lng != null) {
        url += '&lat=$lat&lng=$lng';
      }
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // 3. Update Profil Masjid (DKM)
  static Future<bool> updateMasjid(Map<String, dynamic> payload) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/masjid.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      final data = json.decode(res.body);
      return data['status'] == true;
    } catch (_) {
      return false;
    }
  }

  // 4. Jadwal Kegiatan & Pengumuman
  static Future<List<dynamic>> getKegiatan(int masjidId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/kegiatan.php?masjid_id=$masjidId'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> tambahKegiatan(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/kegiatan.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      final data = json.decode(res.body);
      return data['status'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteKegiatan(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/kegiatan.php?id=$id'));
      final data = json.decode(res.body);
      return data['status'] == true;
    } catch (_) {
      return false;
    }
  }

  // 5. Kas Masjid Real-time
  static Future<Map<String, dynamic>?> getKas(int masjidId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/kas.php?masjid_id=$masjidId'));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> catatKas(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/kas.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      final data = json.decode(res.body);
      return data['status'] == true;
    } catch (_) {
      return false;
    }
  }
}
