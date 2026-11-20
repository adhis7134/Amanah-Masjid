import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

void main() {
  runApp(const AmanahMasjidApp());
}

// Model Sesi Pengguna
class UserModel {
  final int id;
  String nama;
  String email;
  final String role; // 'jamaah' atau 'dkm'
  final int masjidId;
  final String namaMasjid;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.masjidId,
    required this.namaMasjid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 1,
      nama: json['nama_lengkap'] ?? 'Pengguna',
      email: json['email'] ?? json['no_hp'] ?? '',
      role: json['role'] ?? 'jamaah',
      masjidId: int.tryParse(json['masjid_diikuti_id']?.toString() ?? json['masjid_id']?.toString() ?? '1') ?? 1,
      namaMasjid: json['nama_masjid'] ?? json['nama_masjid_diikuti'] ?? 'Masjid Agung Al-Falah',
    );
  }
}

class AmanahMasjidApp extends StatelessWidget {
  const AmanahMasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AmanahMasjid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Tema Kontras Tinggi & Ramah Lansia (Emerald Islamic & Deep Navy)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), // Emerald Green
          primary: const Color(0xFF065F46),
          secondary: const Color(0xFFD97706), // Amber Gold
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// =========================================================================
// 1. SISTEM AUTENTIKASI & MULTI-ROLE (LOGIN & REGISTRASI)
// =========================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController(text: 'jamaah@amanah.id');
  final _passwordCtrl = TextEditingController(text: '123456');
  bool _isLoading = false;

  void _doLogin() async {
    setState(() => _isLoading = true);
    final res = await ApiService.login(_identifierCtrl.text, _passwordCtrl.text);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['status'] == true) {
      final user = UserModel.fromJson(res['data']);
      _navigateByRole(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Login gagal', style: const TextStyle(fontSize: 15)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _navigateByRole(UserModel user) {
    if (user.role == 'dkm') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DkmDashboardScreen(user: user)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => JamaahDashboardScreen(user: user)),
      );
    }
  }

  void _quickFill(String role) {
    if (role == 'dkm') {
      _identifierCtrl.text = 'dkm@amanah.id';
      _passwordCtrl.text = '123456';
    } else {
      _identifierCtrl.text = 'jamaah@amanah.id';
      _passwordCtrl.text = '123456';
    }
  }

  void _showRegisterDialog() {
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final noHpCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final namaMasjidCtrl = TextEditingController();
    final alamatMasjidCtrl = TextEditingController();
    final kotaMasjidCtrl = TextEditingController(text: 'Jakarta');
    String selectedRole = 'jamaah';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pendaftaran Akun Baru", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                const SizedBox(height: 6),
                const Text("Pilih peran Anda untuk mendapatkan fitur yang tepat", style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'jamaah', label: Text('Jamaah / Musafir'), icon: Icon(Icons.person)),
                    ButtonSegment(value: 'dkm', label: Text('Pengurus DKM'), icon: Icon(Icons.admin_panel_settings)),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (val) => setModalState(() => selectedRole = val.first),
                ),
                const SizedBox(height: 16),

                const Text("Data Pribadi Pengguna:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Alamat Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noHpCtrl,
                  decoration: const InputDecoration(labelText: "Nomor WhatsApp", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Kata Sandi", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 16),

                // BAGIAN KHUSUS DKM: TAMBAH MITRA MASJID
                if (selectedRole == 'dkm') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_business, color: Color(0xFF166534), size: 20),
                            SizedBox(width: 8),
                            Text("Daftarkan Mitra Masjid Anda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text("Masjid ini akan langsung terdaftar di sistem agar bisa diikuti oleh para jamaah dan musafir.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: namaMasjidCtrl,
                          decoration: const InputDecoration(
                            labelText: "Nama Masjid / Musala *",
                            hintText: "Contoh: Masjid Jami' Al-Barokah",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.mosque, color: Color(0xFF166534)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: alamatMasjidCtrl,
                          decoration: const InputDecoration(
                            labelText: "Alamat Lengkap Masjid *",
                            hintText: "Jalan, Kelurahan, Kecamatan",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.place, color: Color(0xFF166534)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: kotaMasjidCtrl,
                          decoration: const InputDecoration(
                            labelText: "Kota / Kabupaten",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_city, color: Color(0xFF166534)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF065F46), foregroundColor: Colors.white),
                    onPressed: () async {
                      if (namaCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi nama dan kata sandi.")));
                        return;
                      }

                      if (selectedRole == 'dkm' && namaMasjidCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap isi Nama Masjid mitra Anda!")));
                        return;
                      }

                      final res = await ApiService.register(
                        nama: namaCtrl.text,
                        email: emailCtrl.text,
                        noHp: noHpCtrl.text,
                        password: passCtrl.text,
                        role: selectedRole,
                        namaMasjidBaru: selectedRole == 'dkm' ? namaMasjidCtrl.text : null,
                        alamatMasjidBaru: selectedRole == 'dkm' ? alamatMasjidCtrl.text : null,
                        kotaMasjidBaru: selectedRole == 'dkm' ? kotaMasjidCtrl.text : null,
                      );
                      if (mounted) {
                        Navigator.pop(ctx);
                        if (res['status'] == true) {
                          _identifierCtrl.text = emailCtrl.text.isNotEmpty ? emailCtrl.text : noHpCtrl.text;
                          _passwordCtrl.text = passCtrl.text;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(selectedRole == 'dkm' ? "Pendaftaran DKM & Mitra Masjid Berhasil! Silakan masuk." : "Pendaftaran berhasil! Silakan masuk."),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? "Gagal mendaftar"), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Text(selectedRole == 'dkm' ? "Daftar DKM & Mitra Masjid" : "Daftar Sekarang", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF059669), width: 2),
                  ),
                  child: const Icon(Icons.mosque, size: 64, color: Color(0xFF065F46)),
                ),
                const SizedBox(height: 16),
                const Text(
                  "AmanahMasjid",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Platform Kemitraan Jamaah & Takmir Masjid",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Form Login Kontras Tinggi (Mudah dibaca)
                TextField(
                  controller: _identifierCtrl,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: "Email atau Nomor WhatsApp",
                    labelStyle: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF065F46)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF065F46), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Kata Sandi",
                    labelStyle: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF065F46)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Masuk Besar & Jelas
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065F46),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _doLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Masuk Sekarang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Buka Pendaftaran Akun Baru
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF065F46),
                      side: const BorderSide(color: Color(0xFF065F46), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text("Daftar Akun Baru (Jamaah / DKM)", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showRegisterDialog,
                  ),
                ),
                const SizedBox(height: 24),

                // Demo Switch Role Cepat
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text("Uji Coba Cepat (Akun Demo Multi-Role):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => _quickFill('jamaah'),
                            child: const Text("Isi Akun Jamaah"),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _quickFill('dkm'),
                            child: const Text("Isi Akun DKM"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 2. DASHBOARD JAMAAH & TRAVELER (PENGINGAT, EKSPLORASI, KAS TRANSPARAN)
// =========================================================================
class JamaahDashboardScreen extends StatefulWidget {
  final UserModel user;
  const JamaahDashboardScreen({super.key, required this.user});

  @override
  State<JamaahDashboardScreen> createState() => _JamaahDashboardScreenState();
}

class _JamaahDashboardScreenState extends State<JamaahDashboardScreen> {
  int _tabIndex = 0;
  late int _activeMasjidId;
  String _activeMasjidNama = '';

  @override
  void initState() {
    super.initState();
    _activeMasjidId = widget.user.masjidId;
    _activeMasjidNama = widget.user.namaMasjid;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Tab 1: Jadwal Salat & Hitung Mundur + Papan Informasi
      HomeIbadahTab(
        masjidId: _activeMasjidId,
        namaMasjid: _activeMasjidNama,
      ),
      // Tab 2: Eksplorasi Masjid Terdekat & Rute Traveler (Google Maps Deep-link)
      EksplorasiMasjidTab(
        onPilihMasjid: (id, nama) {
          setState(() {
            _activeMasjidId = id;
            _activeMasjidNama = nama;
            _tabIndex = 0; // Balik ke beranda masjid terpilih
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Mengikuti $nama"), backgroundColor: const Color(0xFF065F46)),
          );
        },
      ),
      // Tab 3: Profil Akun Jamaah
      AkunProfileTab(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("AmanahMasjid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Masjid Diikuti: $_activeMasjidNama", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF065F46),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Keluar",
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Jadwal & Warta',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Cari Masjid (GPS)',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun Saya',
          ),
        ],
      ),
    );
  }
}

// Tab 1: Home Ibadah + Hitung Mundur + Papan Informasi
class HomeIbadahTab extends StatefulWidget {
  final int masjidId;
  final String namaMasjid;
  const HomeIbadahTab({super.key, required this.masjidId, required this.namaMasjid});

  @override
  State<HomeIbadahTab> createState() => _HomeIbadahTabState();
}

class _HomeIbadahTabState extends State<HomeIbadahTab> {
  List<dynamic> _kegiatan = [];
  bool _isLoading = true;
  Timer? _timer;
  String _countdownText = "Menghitung...";
  String _nextPrayer = "Memuat...";
  Map<String, String> _jadwal = {
    "Subuh": "04:03",
    "Dzuhur": "11:40",
    "Ashar": "15:01",
    "Maghrib": "17:52",
    "Isya": "19:04",
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadJadwalLokal();
  }

  void _loadJadwalLokal() async {
    // Mengambil jadwal salat dinamis berdasarkan lokasi dan zona waktu saat ini
    final data = await ApiService.getJadwalSholat();
    if (data != null && mounted) {
      setState(() {
        _jadwal = {
          "Subuh": data['subuh'] ?? "04:03",
          "Dzuhur": data['dzuhur'] ?? "11:40",
          "Ashar": data['ashar'] ?? "15:01",
          "Maghrib": data['maghrib'] ?? "17:52",
          "Isya": data['isya'] ?? "19:04",
        };
      });
    }
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadData() async {
    final list = await ApiService.getKegiatan(widget.masjidId);
    if (mounted) {
      setState(() {
        _kegiatan = list;
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      // Parser jam & menit jadwal sholat hari ini
      DateTime parseTime(String timeStr, {bool tomorrow = false}) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final date = tomorrow ? now.add(const Duration(days: 1)) : now;
        return DateTime(date.year, date.month, date.day, hour, min, 0);
      }

      final subuh = parseTime(_jadwal["Subuh"]!);
      final dzuhur = parseTime(_jadwal["Dzuhur"]!);
      final ashar = parseTime(_jadwal["Ashar"]!);
      final maghrib = parseTime(_jadwal["Maghrib"]!);
      final isya = parseTime(_jadwal["Isya"]!);

      DateTime nextTarget;
      String nextName;

      if (now.isBefore(subuh)) {
        nextTarget = subuh;
        nextName = "Subuh";
      } else if (now.isBefore(dzuhur)) {
        nextTarget = dzuhur;
        nextName = "Dzuhur";
      } else if (now.isBefore(ashar)) {
        nextTarget = ashar;
        nextName = "Ashar";
      } else if (now.isBefore(maghrib)) {
        nextTarget = maghrib;
        nextName = "Maghrib";
      } else if (now.isBefore(isya)) {
        nextTarget = isya;
        nextName = "Isya";
      } else {
        // Lewat Isya, menuju Subuh besok
        nextTarget = parseTime(_jadwal["Subuh"]!, tomorrow: true);
        nextName = "Subuh Besok";
      }

      final diff = nextTarget.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

      if (mounted) {
        setState(() {
          _nextPrayer = nextName;
          _countdownText = "-$hours:$minutes:$seconds";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Utama Hitung Mundur Waktu Sholat (Kontras Tinggi Ramah Lansia)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Menuju Sholat $_nextPrayer (WIB)", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const Icon(Icons.notifications_active, color: Colors.amber, size: 24),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _countdownText,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WaktuItem(nama: "Subuh", waktu: _jadwal["Subuh"]!, isHighlight: _nextPrayer == "Subuh"),
                  _WaktuItem(nama: "Dzuhur", waktu: _jadwal["Dzuhur"]!, isHighlight: _nextPrayer == "Dzuhur"),
                  _WaktuItem(nama: "Ashar", waktu: _jadwal["Ashar"]!, isHighlight: _nextPrayer == "Ashar"),
                  _WaktuItem(nama: "Maghrib", waktu: _jadwal["Maghrib"]!, isHighlight: _nextPrayer == "Maghrib"),
                  _WaktuItem(nama: "Isya", waktu: _jadwal["Isya"]!, isHighlight: _nextPrayer == "Isya"),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Papan Informasi & Warta Masjid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Papan Informasi & Kajian", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        const SizedBox(height: 8),

        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_kegiatan.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("Belum ada jadwal kajian atau pengumuman dari masjid ini."),
            ),
          )
        else
          ..._kegiatan.map((item) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item['kategori'] == 'jumat' ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['kategori'] == 'jumat' ? "PETUGAS JUMAT" : "KAJIAN / WARTA",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item['kategori'] == 'jumat' ? Colors.amber.shade900 : Colors.green.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(item['judul'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      if (item['penceramah'] != null && item['penceramah'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text("Pemateri/Petugas: ${item['penceramah']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                      const SizedBox(height: 6),
                      Text("Waktu: ${item['tanggal']} • ${item['waktu']} WIB", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      if (item['deskripsi'] != null && item['deskripsi'].isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item['deskripsi'], style: const TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _WaktuItem extends StatelessWidget {
  final String nama;
  final String waktu;
  final bool isHighlight;
  const _WaktuItem({required this.nama, required this.waktu, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(nama, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlight ? Colors.amber : Colors.white24,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            waktu,
            style: TextStyle(
              color: isHighlight ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// Tab 2: Eksplorasi Masjid Terdekat & Rute Navigasi Traveler (Hybrid UX)
class EksplorasiMasjidTab extends StatefulWidget {
  final Function(int, String) onPilihMasjid;
  const EksplorasiMasjidTab({super.key, required this.onPilihMasjid});

  @override
  State<EksplorasiMasjidTab> createState() => _EksplorasiMasjidTabState();
}

class _EksplorasiMasjidTabState extends State<EksplorasiMasjidTab> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _listMasjid = [];
  bool _isLoading = true;

  // Koordinat GPS traveler (simulasi Jakarta Pusat)
  static const double _userLat = -6.2087634;
  static const double _userLng = 106.8455990;

  // Jadwal sholat hari ini (diambil dari API)
  Map<String, String> _jadwal = {
    "Subuh": "04:35",
    "Dzuhur": "11:58",
    "Ashar": "15:15",
    "Maghrib": "18:05",
    "Isya": "19:18",
  };

  @override
  void initState() {
    super.initState();
    _loadJadwal();
    _cari();
  }

  void _loadJadwal() async {
    final data = await ApiService.getJadwalSholat();
    if (data != null && mounted) {
      setState(() {
        _jadwal = {
          "Subuh": data['subuh'] ?? "04:35",
          "Dzuhur": data['dzuhur'] ?? "11:58",
          "Ashar": data['ashar'] ?? "15:15",
          "Maghrib": data['maghrib'] ?? "18:05",
          "Isya": data['isya'] ?? "19:18",
        };
      });
    }
  }

  void _cari() async {
    setState(() => _isLoading = true);
    final res = await ApiService.searchMasjid(
        query: _searchCtrl.text, lat: _userLat, lng: _userLng);
    if (mounted) {
      setState(() {
        _listMasjid = res;
        _isLoading = false;
      });
    }
  }

  // Deep Link Navigasi 100% Gratis via Google Maps
  void _bukaGoogleMaps(double lat, double lng, String nama) async {
    final uri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Buka peta semua masjid terdekat di Google Maps
  void _bukaSemuaMasjidDiPeta() async {
    final uri = Uri.parse(
        "https://www.google.com/maps/search/masjid/@$_userLat,$_userLng,14z");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Fasilitas Badges ────────────────────────────────────────────────
  Widget _buildFasilitasBadges(dynamic fasilitasRaw) {
    final String fasilitasStr = (fasilitasRaw ?? '').toString();
    if (fasilitasStr.trim().isEmpty) return const SizedBox.shrink();

    final Map<String, Map<String, dynamic>> badgeMap = {
      '24jam': {
        'icon': '🌙',
        'label': 'Buka 24 Jam',
        'bg': const Color(0xFF1E3A5F),
      },
      'ramah_lansia': {
        'icon': '♿',
        'label': 'Ramah Lansia',
        'bg': const Color(0xFF065F46),
      },
      'wudhu_duduk': {
        'icon': '🚿',
        'label': 'Wudhu Duduk',
        'bg': const Color(0xFF0369A1),
      },
      'parkir_luas': {
        'icon': '🅿️',
        'label': 'Parkir Luas',
        'bg': const Color(0xFF6B21A8),
      },
      'toilet_bersih': {
        'icon': '🚻',
        'label': 'Toilet Bersih',
        'bg': const Color(0xFFB45309),
      },
    };

    final keys = fasilitasStr.split(',').map((e) => e.trim()).toList();
    final chips = keys
        .where((k) => badgeMap.containsKey(k))
        .map((k) {
          final info = badgeMap[k]!;
          return Container(
            margin: const EdgeInsets.only(right: 6, bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: info['bg'] as Color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${info['icon']} ${info['label']}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          );
        })
        .toList();

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(children: chips),
    );
  }

  // ── Next Prayer Badge per Masjid ───────────────────────────────────
  Widget _buildNextPrayerBadge(double jarakKm) {
    final now = DateTime.now();

    DateTime parseTime(String t) {
      final parts = t.split(':');
      return DateTime(
          now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    }

    final namaUrutan = ["Subuh", "Dzuhur", "Ashar", "Maghrib", "Isya"];
    String nextName = "Subuh";
    String nextTime = _jadwal["Subuh"] ?? "04:35";

    for (final nama in namaUrutan) {
      final t = parseTime(_jadwal[nama] ?? "23:59");
      if (now.isBefore(t)) {
        nextName = nama;
        nextTime = _jadwal[nama] ?? "-";
        break;
      }
    }

    final menitBerkendara = jarakKm > 0 ? (jarakKm / 40 * 60).round() : 0;
    final String jarakLabel = menitBerkendara > 0
        ? "• ~$menitBerkendara menit berkendara"
        : "• Lokasi ini";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFF16A34A), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🕌 ", style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              "$nextName $nextTime WIB $jarakLabel",
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Peta Mini Preview (tanpa API key) ─────────────────────────────
  Widget _buildMapPreview() {
    return GestureDetector(
      onTap: _bukaSemuaMasjidDiPeta,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        height: 130,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Stack(
          children: [
            // Grid pattern background (simulasi peta)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(painter: _MapGridPainter()),
              ),
            ),
            // Konten overlay
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.location_on,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📍 Masjid Terdekat di Sekitar Anda",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text("Ketuk untuk buka di Google Maps",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Pin masjid simulasi
                  Row(
                    children: [
                      _pinBadge("🕌 Al-Falah", "0.0 km"),
                      const SizedBox(width: 8),
                      _pinBadge("🕌 Baitul Ihsan", "3.5 km"),
                      const SizedBox(width: 8),
                      _pinBadge("🕌 Rest Area", "27.4 km"),
                    ],
                  ),
                ],
              ),
            ),
            // Tombol "Lihat Peta" kanan bawah
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new,
                        size: 14, color: Color(0xFF065F46)),
                    SizedBox(width: 4),
                    Text("Buka Peta",
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinBadge(String nama, String jarak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30)),
      child: Text("$nama\n$jarak",
          style: const TextStyle(
              color: Colors.white, fontSize: 10, height: 1.3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _cari(),
            decoration: InputDecoration(
              hintText: "Cari nama masjid atau lokasi...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  IconButton(icon: const Icon(Icons.send), onPressed: _cari),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // 2. Peta Mini Preview (Hybrid UX)
        _buildMapPreview(),

        // 3. Daftar Kartu Masjid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _listMasjid.length,
                  itemBuilder: (ctx, i) {
                    final m = _listMasjid[i];
                    final double lat =
                        double.tryParse(m['latitude'].toString()) ?? 0.0;
                    final double lng =
                        double.tryParse(m['longitude'].toString()) ?? 0.0;
                    final double jarakKm = m['jarak_km'] != null
                        ? double.parse(m['jarak_km'].toString())
                        : 0.0;
                    final String jarakLabel =
                        "${jarakKm.toStringAsFixed(1)} km";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header: nama + jarak badge ──
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    m['nama_masjid'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text("📍 $jarakLabel",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(m['alamat'] ?? '',
                                style:
                                    const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 10),

                            // ── Fasilitas Badges ──
                            _buildFasilitasBadges(m['fasilitas']),

                            // ── Next Prayer Badge ──
                            _buildNextPrayerBadge(jarakKm),

                            // ── Tombol Aksi ──
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.bookmark_add,
                                        size: 18),
                                    label: const Text("Ikuti Masjid"),
                                    onPressed: () => widget.onPilihMasjid(
                                        int.parse(m['id'].toString()),
                                        m['nama_masjid']),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF065F46),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.navigation,
                                        size: 18),
                                    label: const Text("Rute (Peta)"),
                                    onPressed: () =>
                                        _bukaGoogleMaps(lat, lng, m['nama_masjid']),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Custom painter untuk background grid peta simulasi
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    // Garis horizontal
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Garis vertikal
    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Lingkaran radius simulasi
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 40, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 70, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tab 3: Transparansi Kas Masjid (Read-Only Jamaah)
class TransparansiKasTab extends StatefulWidget {
  final int masjidId;
  final String namaMasjid;
  const TransparansiKasTab({super.key, required this.masjidId, required this.namaMasjid});

  @override
  State<TransparansiKasTab> createState() => _TransparansiKasTabState();
}

class _TransparansiKasTabState extends State<TransparansiKasTab> {
  Map<String, dynamic>? _kasData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKas();
  }

  void _loadKas() async {
    final res = await ApiService.getKas(widget.masjidId);
    if (mounted) {
      setState(() {
        _kasData = res;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(num nominal) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(nominal);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final summary = _kasData?['summary'] ?? {'saldo': 0, 'total_masuk': 0, 'total_keluar': 0};
    final items = (_kasData?['data'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () async => _loadKas(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ringkasan Saldo Akhir
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Saldo Kas Transparan (Terbuka)", style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(summary['saldo'] ?? 0),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("Total Infaq Masuk", style: TextStyle(fontSize: 12, color: Colors.green)),
                          Text(_formatRupiah(summary['total_masuk'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Total Pengeluaran", style: TextStyle(fontSize: 12, color: Colors.red)),
                          Text(_formatRupiah(summary['total_keluar'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Rincian Pemasukan & Pengeluaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (items.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Belum ada pencatatan kas.")))
          else
            ...items.map((it) {
              final isMasuk = it['tipe'] == 'masuk';
              final nominal = num.tryParse(it['nominal'].toString()) ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMasuk ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    child: Icon(isMasuk ? Icons.arrow_downward : Icons.arrow_upward, color: isMasuk ? Colors.green : Colors.red),
                  ),
                  title: Text(it['keterangan'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("${it['tanggal']} • ${it['kategori']}"),
                  trailing: Text(
                    (isMasuk ? "+ " : "- ") + _formatRupiah(nominal),
                    style: TextStyle(fontWeight: FontWeight.bold, color: isMasuk ? Colors.green : Colors.red),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. DASHBOARD PENGURUS MASJID / DKM (MANAJEMEN PROFIL, CRUD KEGIATAN, BUKU KAS)
// =========================================================================
class DkmDashboardScreen extends StatefulWidget {
  final UserModel user;
  const DkmDashboardScreen({super.key, required this.user});

  @override
  State<DkmDashboardScreen> createState() => _DkmDashboardScreenState();
}

class _DkmDashboardScreenState extends State<DkmDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DkmKelolaKegiatanTab(masjidId: widget.user.masjidId),
      DkmBukuKasTab(masjidId: widget.user.masjidId, userId: widget.user.id),
      DkmProfilMasjidTab(masjidId: widget.user.masjidId),
      AkunProfileTab(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Panel Pengurus DKM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.user.namaMasjid, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A), // Dark Navy Kontras untuk DKM
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Keluar",
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Kegiatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Buku Kas',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_mall_directory_outlined),
            selectedIcon: Icon(Icons.store_mall_directory),
            label: 'Profil Masjid',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Akun DKM',
          ),
        ],
      ),
    );
  }
}

// DKM Tab 1: Kelola Kegiatan & Pengumuman (CRUD)
class DkmKelolaKegiatanTab extends StatefulWidget {
  final int masjidId;
  const DkmKelolaKegiatanTab({super.key, required this.masjidId});

  @override
  State<DkmKelolaKegiatanTab> createState() => _DkmKelolaKegiatanTabState();
}

class _DkmKelolaKegiatanTabState extends State<DkmKelolaKegiatanTab> {
  List<dynamic> _kegiatan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKegiatan();
  }

  void _loadKegiatan() async {
    final data = await ApiService.getKegiatan(widget.masjidId);
    if (mounted) setState(() { _kegiatan = data; _isLoading = false; });
  }

  void _showFormTambah() {
    final judulCtrl = TextEditingController();
    final penceramahCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    String kategori = 'kajian';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Kegiatan / Pengumuman"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: "Judul Acara / Pengumuman")),
              TextField(controller: penceramahCtrl, decoration: const InputDecoration(labelText: "Penceramah / Petugas")),
              DropdownButtonFormField<String>(
                initialValue: kategori,
                items: const [
                  DropdownMenuItem(value: 'kajian', child: Text("Kajian Rutin")),
                  DropdownMenuItem(value: 'jumat', child: Text("Petugas Jumat")),
                  DropdownMenuItem(value: 'pengumuman', child: Text("Pengumuman Penting")),
                ],
                onChanged: (v) => kategori = v ?? 'kajian',
              ),
              TextField(controller: deskripsiCtrl, decoration: const InputDecoration(labelText: "Deskripsi Singkat")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (judulCtrl.text.isNotEmpty) {
                await ApiService.tambahKegiatan({
                  'masjid_id': widget.masjidId,
                  'judul': judulCtrl.text,
                  'penceramah': penceramahCtrl.text,
                  'kategori': kategori,
                  'deskripsi': deskripsiCtrl.text,
                  'tanggal': DateTime.now().toIso8601String().substring(0, 10),
                  'waktu': '18:30:00',
                  'tempat': 'Masjid',
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadKegiatan();
                }
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Jadwal"),
        onPressed: _showFormTambah,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _kegiatan.length,
              itemBuilder: (ctx, i) {
                final k = _kegiatan[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(k['judul'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${k['tanggal']} • ${k['kategori']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await ApiService.deleteKegiatan(int.parse(k['id'].toString()));
                        _loadKegiatan();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// DKM Tab 2: Buku Kas Digital (Input Real-time)
class DkmBukuKasTab extends StatefulWidget {
  final int masjidId;
  final int userId;
  const DkmBukuKasTab({super.key, required this.masjidId, required this.userId});

  @override
  State<DkmBukuKasTab> createState() => _DkmBukuKasTabState();
}

class _DkmBukuKasTabState extends State<DkmBukuKasTab> {
  final _nominalCtrl = TextEditingController();
  final _ketCtrl = TextEditingController();
  String _tipe = 'masuk';
  final String _kategori = 'Kotak Amal Jumat';
  bool _isLoading = false;

  void _simpanKas() async {
    final nominal = double.tryParse(_nominalCtrl.text) ?? 0;
    if (nominal <= 0 || _ketCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi data kas dengan lengkap!")));
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.catatKas({
      'masjid_id': widget.masjidId,
      'tipe': _tipe,
      'nominal': nominal,
      'kategori': _kategori,
      'keterangan': _ketCtrl.text,
      'user_id': widget.userId,
    });
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        _nominalCtrl.clear();
        _ketCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaksi berhasil disimpan & sinkron ke Jamaah!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan transaksi."), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Catat Keuangan Masjid (Buku Kas)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Setiap transaksi yang dicatat akan langsung muncul pada aplikasi Jamaah secara transparan.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'masuk', label: Text('Pemasukan (Infak/Kotak Amal)')),
              ButtonSegment(value: 'keluar', label: Text('Pengeluaran (Operasional)')),
            ],
            selected: {_tipe},
            onSelectionChanged: (val) => setState(() => _tipe = val.first),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nominalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nominal (Rp)", border: OutlineInputBorder(), prefixText: "Rp "),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _ketCtrl,
            decoration: const InputDecoration(labelText: "Keterangan", border: OutlineInputBorder(), hintText: "Misal: Donasi Karpet / Tagihan Listrik"),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              onPressed: _isLoading ? null : _simpanKas,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan Transaksi Kas"),
            ),
          )
        ],
      ),
    );
  }
}

// DKM Tab 3: Manajemen Profil Masjid
class DkmProfilMasjidTab extends StatefulWidget {
  final int masjidId;
  const DkmProfilMasjidTab({super.key, required this.masjidId});

  @override
  State<DkmProfilMasjidTab> createState() => _DkmProfilMasjidTabState();
}

class _DkmProfilMasjidTabState extends State<DkmProfilMasjidTab> {
  final _namaCtrl = TextEditingController(text: 'Masjid Agung Al-Falah');
  final _alamatCtrl = TextEditingController(text: 'Jl. Sudirman No. 12');
  final _kontakCtrl = TextEditingController(text: '081298765432');
  final _deskripsiCtrl = TextEditingController(text: 'Masjid transit ramah musafir dan lansia.');

  void _simpanProfil() async {
    final success = await ApiService.updateMasjid({
      'id': widget.masjidId,
      'nama_masjid': _namaCtrl.text,
      'alamat': _alamatCtrl.text,
      'kontak_dkm': _kontakCtrl.text,
      'deskripsi': _deskripsiCtrl.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Profil masjid berhasil diperbarui!" : "Gagal menyimpan"), backgroundColor: success ? Colors.green : Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Profil & Informasi Masjid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: "Nama Masjid", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _alamatCtrl, decoration: const InputDecoration(labelText: "Alamat Lengkap", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _kontakCtrl, decoration: const InputDecoration(labelText: "Nomor Kontak Pengurus / DKM", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _deskripsiCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Deskripsi & Fasilitas Masjid", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              onPressed: _simpanProfil,
              child: const Text("Perbarui Profil"),
            ),
          )
        ],
      ),
    );
  }
}

// =========================================================================
// 4. TAB MANAJEMEN AKUN & PROFIL (BERLAKU UNTUK JAMAAH & DKM)
// =========================================================================
class AkunProfileTab extends StatefulWidget {
  final UserModel user;
  const AkunProfileTab({super.key, required this.user});

  @override
  State<AkunProfileTab> createState() => _AkunProfileTabState();
}

class _AkunProfileTabState extends State<AkunProfileTab> {
  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _noHpCtrl;
  final _passwordBaruCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.user.nama);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _noHpCtrl = TextEditingController(text: '');
    _loadUserDetail();
  }

  void _loadUserDetail() async {
    final res = await ApiService.getProfile(widget.user.id);
    if (res['status'] == true && mounted) {
      final d = res['data'];
      setState(() {
        _namaCtrl.text = d['nama_lengkap'] ?? '';
        _emailCtrl.text = d['email'] ?? '';
        _noHpCtrl.text = d['no_hp'] ?? '';
      });
    }
  }

  void _simpanPerubahan() async {
    if (_namaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama lengkap wajib diisi.")));
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.updateProfile({
      'user_id': widget.user.id,
      'nama_lengkap': _namaCtrl.text,
      'email': _emailCtrl.text,
      'no_hp': _noHpCtrl.text,
      'password_baru': _passwordBaruCtrl.text.isNotEmpty ? _passwordBaruCtrl.text : null,
    });
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        setState(() {
          widget.user.nama = _namaCtrl.text;
          widget.user.email = _emailCtrl.text;
        });
        _passwordBaruCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil akun berhasil diperbarui!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memperbarui profil."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDkm = widget.user.role == 'dkm';
    final primaryColor = isDkm ? const Color(0xFF0F172A) : const Color(0xFF065F46);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar Profil Kontras Tinggi
          CircleAvatar(
            radius: 44,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            child: Icon(Icons.person, size: 54, color: primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            widget.user.nama,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDkm ? const Color(0xFFE2E8F0) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isDkm ? "Pengurus DKM / Takmir" : "Jamaah Masjid",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDkm ? const Color(0xFF0F172A) : const Color(0xFF065F46),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Detail Info Masjid Terikat
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.mosque, color: primaryColor),
              title: Text(isDkm ? "Masjid Kelolaan" : "Masjid yang Diikuti", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(widget.user.namaMasjid, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),

          // Form Edit Profil
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Pengaturan Data Akun", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _namaCtrl,
            decoration: InputDecoration(
              labelText: "Nama Lengkap",
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Alamat Email",
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noHpCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Nomor WhatsApp / HP",
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordBaruCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Ganti Password Baru (Opsional)",
              hintText: "Kosongkan jika tidak ingin mengubah",
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _simpanPerubahan,
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
              label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Simpan Perubahan Akun", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Keluar Akun
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Keluar dari Akun"),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
