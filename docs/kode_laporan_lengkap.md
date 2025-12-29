# Dokumen Lampiran Kode Lengkap untuk Laporan Roti515

Dokumen ini berisi kode sumber (*full source code*) lengkap untuk modul-modul penting yang diajukan dalam pengerjaan laporan Anda:
1. **PB-01 & PB-02 (Autentikasi: Login & Logout)**
2. **PB-03 (Dashboard Admin: Ringkasan Penjualan)**
3. **PB-04 (Manajemen Produk: CRUD Admin)**
4. **PB-05 (Beranda Pelanggan: Katalog Roti)**

---

## 🔑 PB-01 & PB-02 (Autentikasi)

### 1. `lib/features/auth/screens/login_screen.dart`
Halaman antarmuka masuk untuk pelanggan dan admin.

```dart
import 'dart:convert'; // Untuk melakukan encoding/decoding JSON saat mengirim data ke API
import 'package:flutter/material.dart'; // Library utama Flutter untuk membangun antarmuka pengguna (UI)
import 'package:http/http.dart' as http; // Digunakan untuk melakukan HTTP request (GET, POST, dll) ke backend

import 'package:google_fonts/google_fonts.dart'; // Library untuk menggunakan font Google secara langsung

// Mengimpor konstanta warna yang digunakan dalam aplikasi
import '../../../core/utils/premium_snackbar.dart';
// Mengimpor daftar rute untuk navigasi antar halaman
import '../../../routes/app_routes.dart';
// Mengimpor file ApiService yang menyimpan alamat endpoint backend
import '../../../core/network/api_service.dart';


// Mengimpor komponen-komponen UI modular khusus untuk halaman login
import '../widgets/login_logo.dart';
import '../widgets/login_tab_selector.dart';
import '../widgets/login_input_field.dart';
import '../widgets/login_button.dart';
import '../widgets/login_footer.dart';
import 'package:roti_515/core/theme/app_theme.dart';

// Kelas utama untuk Halaman Login. Menggunakan StatefulWidget karena halamannya interaktif dan state-nya bisa berubah.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// State dari LoginScreen, menggunakan SingleTickerProviderStateMixin agar bisa menggunakan kontroler animasi seperti TabController
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
      
  // Controller untuk menangkap dan membaca teks yang diketik di kolom input Email
  final TextEditingController _emailController = TextEditingController();
  // Controller untuk menangkap teks di kolom input Password
  final TextEditingController _passwordController = TextEditingController();
  // Controller untuk mengelola tab "User" dan "Admin"
  late TabController _tabController;

  // Variabel penanda (flag) apakah proses loading sedang berjalan
  bool _isLoading = false;
  // Variabel untuk menyembunyikan atau menampilkan password (true = sembunyi)
  bool _isObscure = true;

  // Getter singkat untuk mengambil URL endpoint login dari ApiService terpusat
  String get _apiUrl => ApiService.login;

  @override
  void initState() {
    super.initState();
    // Menginisialisasi TabController dengan 2 tab ("User" dan "Admin")
    _tabController = TabController(length: 2, vsync: this);
    // Menambahkan listener untuk membangun ulang layar saat perpindahan tab terjadi
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Mematikan controller untuk membersihkan memory saat halaman ditutup (mencegah memory leak)
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi asinkron yang dieksekusi saat tombol Login ditekan
  Future<void> _login() async {
    // Validasi sederhana: hentikan jika email atau password kosong
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      PremiumSnackbar.showError(context, "Email dan Password wajib diisi");
      return;
    }

    // Mengubah statur loading menjadi true agar tombol berubah jadi ikon berputar
    setState(() => _isLoading = true);

    try {
      // Mengirimkan permintaan HTTP POST ke backend
      final response = await http.post(
        Uri.parse(_apiUrl), // URL API dari konfigurasi network
        headers: {"Content-Type": "application/json"}, // Tipe konten berupa JSON
        body: jsonEncode({
          "email": _emailController.text.trim(), // Data email, hapus spasi berlebih
          "password": _passwordController.text, // Data password
        }),
      ).timeout(Duration(seconds: 10)); // Diberi batas waktu 10 detik

      // Mengurai string JSON dari server menjadi objek (Map) Dart
      final data = jsonDecode(response.body);

      // Jika balasan statusnya 200 (OK/Sukses), serta widget masih terpasang (mounted)
      if (response.statusCode == 200 && mounted) {
        // Ambil token dan data user dari JSON JSON respon
        final String token = data['token'];
        final String userRole = data['user']['role'];
        final String userName = data['user']['name'];
        final String? photoUrl = data['user']['photo_url'];

        // Langsung pindah ke layar sukses dan bawa data auth-nya
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.loginSuccess, 
          arguments: {
            'token': token,
            'role': userRole,
            'name': userName,
            'photoUrl': photoUrl,
            'isAdmin': userRole == 'admin'
          }
        );
      } else if (mounted) {
        // Tampilkan pesan error jika status code bukan 200 (misalnya salah password)
        PremiumSnackbar.showError(context, data['error'] ?? "Gagal login");
      }
    } catch (e) {
      // Cek apakah terjadi error lainnya (misal error koneksi internet)
      if (mounted) {
        PremiumSnackbar.showError(context, "Gagal terhubung ke server. Cek koneksi.");
      }
    } finally {
      // Pastikan status loading dikembalikan ke false di akhir try/catch
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold merepresentasikan kerangka layar dasar dari desain material Flutter
    return Scaffold(
      backgroundColor: context.colors.authBackground, // Set warna latar layar
      body: SafeArea( // SafeArea menjaga agar widget tidak tertutup oleh poni/status bar layar HP
        child: SingleChildScrollView( // Agar seluruh isi halaman bisa di-scroll ke bawah saat keyboard muncul
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Jarak di kanan kiri
          child: Column( // Menata semua widget secara berurut ke bawah (vertikal)
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Widget Kustom Logo Login Aplikasi
              LoginLogo(),
              SizedBox(height: 32),
              
              // Menampilkan Pilihan Tab (User / Admin)
              LoginTabSelector(controller: _tabController),
              SizedBox(height: 32),
              
              // Widget kustom Input TextField untuk Email
              LoginInputField(
                controller: _emailController,
                label: "Email",
                hint: "Masukkan Email Atau Nama Pengguna",
                icon: Icons.mail_outline_rounded,
              ),
              SizedBox(height: 20),
              
              // Widget kustom Input TextField untuk Kata Sandi (Password)
              LoginInputField(
                controller: _passwordController,
                label: "Password",
                hint: "Masukkan Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true, // Menandakan bahwa textfield ini bertindak sebagai tempat password (termasuk menutupi teks)
                obscureText: _isObscure, // Status bool teks terlihat/sembunyi
                onSuffixTap: () => setState(() => _isObscure = !_isObscure), // SetState membalikkan visibilitas
              ),

              // Bagian Lupa Password yang diletakkan rata kanan (centerRight)
              if (_tabController.index == 0) // Hanya tampil di tab User
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: Text(
                      "Lupa Password?",
                      style: GoogleFonts.plusJakartaSans(
                        color: context.colors.primaryOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16),

              // Tombol Login Kustom yang menyematkan status memuat (loading) dan trigger fungsi _login
              LoginButton(isLoading: _isLoading, onPressed: _login),
              SizedBox(height: 32),

              // Widget tulisan "Belum punya akun? Daftar" - Hanya tampil di tab User
              if (_tabController.index == 0)
                LoginFooter(),
              
              const SizedBox(height: 40), // Jarak terluar agar isi tidak mepet di akhir guliran layar
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. `lib/features/auth/providers/auth_provider.dart`
Manajemen State Autentikasi secara global (menggunakan ChangeNotifier).

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthProvider: Pusat manajemen status autentikasi di seluruh aplikasi.
/// Kelas ini memberitahu UI saat user login atau logout.
class AuthProvider extends ChangeNotifier {
  // Variabel privat untuk menyimpan data sesi di memori (selama aplikasi berjalan)
  String? _token;
  String? _role;
  String? _name;
  String? _photoUrl;
  String? _address; // Tambahan lokal untuk address
  String? _phone;   // Tambahan lokal untuk phone

  // Getter: Cara aman untuk mengakses data autentikasi dari luar kelas
  String? get token => _token;
  String? get role => _role;
  String? get name => _name;
  String? get photoUrl => _photoUrl;
  String? get address => _address;
  String? get phone => _phone;

  // Fungsi helper: Mengecek status apakah user sudah login atau bertindak sebagai admin
  bool get isLoggedIn => _token != null;
  bool get isAdmin => _role == 'admin';

  // --- KUNCI PENYIMPANAN PERMANEN ---
  // Nama label (key) untuk menyimpan data di memori HP (Shared Preferences)
  static final String _keyToken = "auth_token";
  static final String _keyRole = "user_role";
  static final String _keyName = "user_name";
  static final String _keyPhotoUrl = "user_photo_url";
  static final String _keyAddress = "user_address";
  static final String _keyPhone = "user_phone";

  /// MEMUAT SESI (Fungsi Auto-Login):
  /// Dipanggil saat aplikasi pertama kali dibuka untuk mengecek data login lama.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Mengambil data dari penyimpanan permanen HP
    _token = prefs.getString(_keyToken);
    _role = prefs.getString(_keyRole);
    _name = prefs.getString(_keyName);
    _photoUrl = prefs.getString(_keyPhotoUrl);
    _address = prefs.getString(_keyAddress);
    _phone = prefs.getString(_keyPhone);
    
    // Memberitahu UI (Listener) bahwa data sesi sudah siap digunakan
    notifyListeners();
  }

  /// UPDATE PHOTO URL:
  /// Memperbarui URL foto profil secara global tanpa harus login ulang.
  Future<void> updatePhotoUrl(String? url) async {
    _photoUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString(_keyPhotoUrl, url);
    } else {
      await prefs.remove(_keyPhotoUrl);
    }
    notifyListeners();
  }

  /// UPDATE PROFILE LOKAL:
  /// Menyimpan nama, phone, dan alamat secara lokal karena API mungkin tidak menyimpannya.
  Future<void> updateProfileData({String? name, String? phone, String? address}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      _name = name;
      await prefs.setString(_keyName, name);
    }
    if (phone != null && phone.isNotEmpty) {
      _phone = phone;
      await prefs.setString(_keyPhone, phone);
    }
    if (address != null && address.isNotEmpty) {
      _address = address;
      await prefs.setString(_keyAddress, address);
    }
    notifyListeners();
  }

  /// LOGIN (Simpan Sesi):
  /// Dipanggil setelah user berhasil melakukan request login ke server.
  Future<void> login(String newToken, {String? role, String? name, String? photoUrl}) async {
    _token = newToken;
    _role = role;
    _name = name;
    _photoUrl = photoUrl;

    // Menyimpan data secara permanen ke memori HP (Persistence)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, newToken);
    if (role != null) await prefs.setString(_keyRole, role);
    if (name != null) await prefs.setString(_keyName, name);
    if (photoUrl != null) await prefs.setString(_keyPhotoUrl, photoUrl);

    // Memicu perubahan UI di seluruh aplikasi (misal: tombol 'Daftar' jadi 'Profil')
    notifyListeners();
  }

  /// LOGOUT (Hapus Sesi):
  /// Menghapus semua data sesi baik dari memori aplikasi maupun penyimpanan HP.
  Future<void> logout() async {
    _token = null;
    _role = null;
    _name = null;
    _photoUrl = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhotoUrl);
    await prefs.remove(_keyAddress);
    await prefs.remove(_keyPhone);

    // Mengembalikan status aplikasi ke kondisi 'Belum Login'
    notifyListeners();
  }
}
```

---

## 📊 PB-03 (Dashboard Admin)

### 1. `lib/features/admin/dashboard/screens/dashboard_admin_screen.dart`
Tampilan Dashboard Admin dengan kartu statistik dan ringkasan aktivitas.

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/animated_sales_chart.dart';
import '../../profile/screens/admin_profile_screen.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final statsProvider = Provider.of<AdminStatsProvider>(context, listen: false);
    Future.microtask(() => statsProvider.startPolling(auth.token));
  }

  @override
  void dispose() {
    // Memastikan polling berhenti saat admin meninggalkan dashboard
    Provider.of<AdminStatsProvider>(context, listen: false).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<AdminStatsProvider>(context);
    final stats = statsProvider.stats;

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(),
      body: statsProvider.isLoading 
          ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STATS ROW ---
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Total Penjualan", _formatRupiah(stats['total_sales']), stats['sales_growth'], Icons.payments_rounded)),
                      SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Total Pesanan", "${stats['total_orders']}", stats['orders_growth'], Icons.shopping_basket_rounded)),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildStatCard("Pengguna Baru", "${stats['total_users']} orang", stats['users_growth'], Icons.person_add_rounded, isFullWidth: true),

            SizedBox(height: 24),

            // --- SALES CHART ---
            _buildSalesChart(),

            SizedBox(height: 32),

            // --- RECENT ACTIVITIES ---
            Text(
              "Aktivitas Terkini",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: context.colors.textDark
              ),
            ),
            SizedBox(height: 16),
            
            if ((stats['activities'] as List).isEmpty)
              _buildEmptyActivity()
            else
              ... (stats['activities'] as List).map((act) {
                final createdAt = DateTime.parse(act['created_at']).toLocal();
                return _buildActivityItem(
                  act['title'],
                  "${_getTimeAgo(createdAt)} • ${act['subtitle']}",
                  act['type'] == 'order' ? Icons.receipt_long_rounded : Icons.person_add_alt_1_rounded,
                );
              }).toList(),
            
            SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, color: context.colors.textHint, size: 32),
          SizedBox(height: 8),
          Text("Belum ada aktivitas hari ini", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} mnt lalu';
    return 'Baru saja';
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.bgColor,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Image.asset(
              'assets/images/app_icon-removebg-preview.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("roti515", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textDark)),
              Text("Portal Admin", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.primaryOrange)),
            ],
          ),
        ],
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.colors.textDark,
            ),
            onPressed: () => theme.toggleTheme(!theme.isDarkMode),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => AdminProfileScreen()),
              );
            },
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final photoUrl = auth.photoUrl;
                final resolvedUrl = ApiService.getDisplayImage(photoUrl);

                Widget imageChild;
                if (resolvedUrl.isEmpty) {
                  imageChild = Icon(
                    Icons.account_circle_outlined,
                    color: context.colors.primaryOrange,
                    size: 22,
                  );
                } else if (resolvedUrl.startsWith('data:image')) {
                  try {
                    final base64Str = resolvedUrl.split(',').last;
                    final decodedBytes = base64Decode(base64Str);
                    imageChild = Image.memory(
                      decodedBytes,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle_outlined,
                        color: context.colors.primaryOrange,
                        size: 22,
                      ),
                    );
                  } catch (_) {
                    imageChild = Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    );
                  }
                } else {
                  imageChild = Image.network(
                    resolvedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    ),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.primaryOrange,
                          ),
                        ),
                      );
                    },
                  );
                }

                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primaryOrange.withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageChild,
                );
              },
            ),
          ),
        )
      ],
    );
  }

  String _formatRupiah(dynamic value) {
    final num amount = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    final int intAmount = amount.toInt();
    final String s = intAmount.toString();
    final buf = StringBuffer('Rp ');
    final mod = s.length % 3;
    buf.write(s.substring(0, mod == 0 ? 3 : mod));
    for (int i = (mod == 0 ? 3 : mod); i < s.length; i += 3) {
      buf.write('.');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  Widget _buildStatCard(String title, String value, String percent, IconData icon, {bool isFullWidth = false}) {
    final bool isPositive = !percent.startsWith('-');
    final Color growthColor = isPositive ? context.colors.success : Colors.redAccent;
    final IconData growthIcon = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 1))],
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.colors.primaryOrange, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.textDark)),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(growthIcon, color: growthColor, size: 14),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$percent vs minggu lalu',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: growthColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return AnimatedSalesChart();
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.colors.primaryOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: context.colors.primaryOrange, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textDark)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: context.colors.textGrey)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
        ],
      ),
    );
  }
}
```

### 2. `lib/features/admin/dashboard/providers/admin_stats_provider.dart`
State management untuk penarikan data statistik penjualan.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';

class AdminStatsProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {
    "total_sales": 0,
    "total_orders": 0,
    "total_users": 0,
    "sales_growth": "0%",
    "orders_growth": "0%",
    "users_growth": "0%",
    "daily_stats": <Map<String, dynamic>>[],
    "activities": <Map<String, dynamic>>[],
  };
  bool _isLoading = true;
  Timer? _pollingTimer;

  // Token disimpan agar refreshNow() bisa digunakan tanpa passing token
  String? _cachedToken;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  void startPolling(String? token) {
    _cachedToken = token;
    fetchStats(token);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      fetchStats(token, silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh statistik secara langsung (dipanggil setelah admin selesaikan order)
  Future<void> refreshNow([String? token]) async {
    if (token != null) {
      _cachedToken = token;
    }
    await fetchStats(_cachedToken, silent: true);
  }

  Future<void> fetchStats(String? token, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse(ApiService.adminStats),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String salesGrowth = _parseGrowth(
          data['sales_growth'] ?? data['revenue_growth'] ?? data['income_growth'],
        );
        final String ordersGrowth = _parseGrowth(
          data['orders_growth'] ?? data['order_growth'] ?? data['total_orders_growth'],
        );
        final String usersGrowth = _parseGrowth(
          data['users_growth'] ?? data['user_growth'] ?? data['new_users_growth'],
        );

        final dynamic rawSales = data['revenue']
            ?? data['total_revenue']
            ?? data['total_sales']
            ?? data['sales']
            ?? data['income']
            ?? 0;

        final dynamic rawOrders = data['total_order']
            ?? data['total_orders']
            ?? data['orders_count']
            ?? data['order_count']
            ?? data['completed_orders']
            ?? 0;

        final dynamic rawUsers = data['new_users']
            ?? data['total_users']
            ?? data['user_count']
            ?? data['users_count']
            ?? 0;

        _stats = {
          "total_sales": rawSales,
          "total_orders": rawOrders,
          "total_users": rawUsers,
          "sales_growth": salesGrowth,
          "orders_growth": ordersGrowth,
          "users_growth": usersGrowth,
          "daily_stats": data['daily_stats'] ?? [],
          "activities": data['activities'] ?? [],
        };
      } else {
        debugPrint("Stats API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _parseGrowth(dynamic raw) {
    if (raw == null) return '+0%';
    if (raw is String) {
      if (raw.startsWith('+') || raw.startsWith('-')) return raw;
      return '+$raw';
    }
    if (raw is num) {
      final sign = raw >= 0 ? '+' : '';
      return '$sign${raw.toStringAsFixed(0)}%';
    }
    return '+0%';
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
```

---

## 🍞 PB-04 (Manajemen Produk / CRUD Admin)

### 1. `lib/features/admin/product_admin/screens/product_admin_screen.dart`
Daftar produk roti dari perspektif Admin beserta operasi edit, hapus, dan stok.

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_product_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/utils/premium_snackbar.dart';
import '../../../../core/widgets/universal_image.dart';
import 'add_product_screen.dart';
import '../../profile/screens/admin_profile_screen.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';

class ProductAdminScreen extends StatefulWidget {
  const ProductAdminScreen({super.key});

  @override
  State<ProductAdminScreen> createState() => _ProductAdminScreenState();
}

class _ProductAdminScreenState extends State<ProductAdminScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProductProvider>(context, listen: false).fetchProducts();
    });

    _searchController.addListener(() {
      Provider.of<AdminProductProvider>(context, listen: false)
          .setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProductProvider>(context);

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchBar(context),
          ),
          SizedBox(height: 16),
          _buildFilterTabs(context, provider),
          SizedBox(height: 16),
          Expanded(
            child: _buildBodyContent(context, provider),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 90), 
        child: FloatingActionButton(
          backgroundColor: context.colors.primaryOrange,
          elevation: 6,
          onPressed: () {
            Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddProductScreen()),
            );
          },
          child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, AdminProductProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: context.colors.primaryOrange));
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: context.colors.textHint),
            SizedBox(height: 16),
            Text(provider.errorMessage!, style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey), textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchProducts(),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.primaryOrange, shape: StadiumBorder()),
              child: Text("Coba Lagi", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    final products = provider.filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Text("Tidak ada produk ditemukan.", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey)),
      );
    }

    return RefreshIndicator(
      color: context.colors.primaryOrange,
      onRefresh: () => provider.fetchProducts(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 120),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          
          final String name = product["name"] ?? "Tanpa Nama";
          final String priceStr = (product["price"] ?? 0).toString();
          final int stock = product["stock"] ?? 0;
          
          final String imageUrl = (product["image_url"] != null && product["image_url"].toString().isNotEmpty)
              ? product["image_url"] 
              : "https://via.placeholder.com/150"; 
          
          final double rating = (product["rating"] as num?)?.toDouble() ?? 0.0;
          
          return _buildProductCard(context, 
            name: name,
            price: "Rp $priceStr",
            stock: stock,
            imageUrl: imageUrl,
            rating: rating,
            onQuickRestock: () => _showQuickRestockDialog(context, product),
            onEdit: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(initialProduct: product),
                ),
              );
            },
            onDelete: () => _confirmDelete(context, product),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.bgColor.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Image.asset(
              'assets/images/app_icon-removebg-preview.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("roti515", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textDark)),
              Text("Portal Admin", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.primaryOrange)),
            ],
          ),
        ],
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.colors.textDark,
            ),
            onPressed: () => theme.toggleTheme(!theme.isDarkMode),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => AdminProfileScreen()),
              );
            },
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final photoUrl = auth.photoUrl;
                final fullImageUrl = ApiService.getDisplayImage(photoUrl);

                Widget imageChild;
                if (fullImageUrl.isEmpty) {
                  imageChild = Icon(
                    Icons.account_circle_outlined,
                    color: context.colors.primaryOrange,
                    size: 22,
                  );
                } else if (fullImageUrl.startsWith('data:image')) {
                  try {
                    final base64Str = fullImageUrl.split(',').last;
                    final decodedBytes = base64Decode(base64Str);
                    imageChild = Image.memory(
                      decodedBytes,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle_outlined,
                        color: context.colors.primaryOrange,
                        size: 22,
                      ),
                    );
                  } catch (_) {
                    imageChild = Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    );
                  }
                } else {
                  imageChild = Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    ),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.primaryOrange,
                          ),
                        ),
                      );
                    },
                  );
                }

                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primaryOrange.withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageChild,
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: context.colors.textDark),
        decoration: InputDecoration(
          hintText: "Cari Produk",
          hintStyle: GoogleFonts.plusJakartaSans(color: context.colors.textHint, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: context.colors.primaryOrange, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, AdminProductProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.colors.primaryOrange.withValues(alpha: 0.1)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabItem(context, "Semua Produk", 0, provider),
          _buildTabItem(context, "Stok Habis", 1, provider),
          _buildTabItem(context, "Stok Menipis", 2, provider),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String title, int index, AdminProductProvider provider) {
    bool isActive = provider.selectedTab == index;
    return GestureDetector(
      onTap: () => provider.setTab(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? context.colors.primaryOrange : Colors.transparent, width: 3)),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.bold,
            color: isActive ? context.colors.primaryOrange : context.colors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, {
    required String name, required String price, required int stock, required String imageUrl, required double rating,
    required VoidCallback onEdit, required VoidCallback onDelete, VoidCallback? onQuickRestock,
  }) {
    Color stockBgColor = stock == 0 ? Color(0xFFFEE2E2) : stock <= 15 ? Color(0xFFFFEDD5) : Color(0xFFDCFCE7);
    Color stockTextColor = stock == 0 ? Color(0xFFB91C1C) : stock <= 15 ? Color(0xFFC2410C) : Color(0xFF15803D);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: UniversalImage(
              imageUrl: imageUrl, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 80, height: 80, color: context.colors.divider, 
                child: Icon(Icons.image_not_supported_rounded, color: context.colors.textGrey)
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text(price, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.primaryOrange)),
                SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Stok: ", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: context.colors.textGrey)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: stockBgColor, borderRadius: BorderRadius.circular(9999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (stock > 0 && stock <= 15)
                                Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.warning_amber_rounded, size: 12, color: stockTextColor),
                                ),
                              Text("$stock", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: stockTextColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textDark)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (stock <= 15 && onQuickRestock != null) ...[
                _buildActionButton(context, Icons.add_shopping_cart_rounded, context.colors.primaryOrange, onQuickRestock),
                SizedBox(width: 8),
              ],
              _buildActionButton(context, Icons.edit_rounded, Color(0xFF16A34A), onEdit),
              SizedBox(width: 8),
              _buildActionButton(context, Icons.delete_outline_rounded, Color(0xFFEF4444), onDelete),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text("Hapus Produk?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: context.colors.textDark)),
        content: Text("Apakah Anda yakin ingin menghapus ${product['name']}? Tindakan ini tidak dapat dibatalkan.", style: GoogleFonts.plusJakartaSans(color: context.colors.textDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<AdminProductProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final token = auth.token ?? '';
              
              bool success = await provider.deleteProduct(product['id'], token);
              if (mounted) {
                if (success) {
                  PremiumSnackbar.showSuccess(context, "Produk berhasil dihapus");
                } else {
                  PremiumSnackbar.showError(context, "Gagal menghapus produk: ${provider.errorMessage}");
                }
              }
            },
            child: Text("Hapus", style: GoogleFonts.plusJakartaSans(color: context.colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickRestockDialog(BuildContext context, Map<String, dynamic> product) {
    final TextEditingController stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text("Tambah Stok ${product['name']}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Masukkan jumlah stok yang ditambahkan:", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: context.colors.textDark)),
            SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(color: context.colors.textDark),
              decoration: InputDecoration(
                hintText: "Contoh: 10",
                hintStyle: GoogleFonts.plusJakartaSans(color: context.colors.textHint),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.primaryOrange)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final int addedStock = int.tryParse(stockController.text) ?? 0;
              if (addedStock <= 0) {
                PremiumSnackbar.showError(ctx, "Masukkan jumlah stok yang valid");
                return;
              }

              Navigator.pop(ctx);
              final provider = Provider.of<AdminProductProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final int newStock = (product['stock'] ?? 0) + addedStock;

              bool success = await provider.updateProduct(
                id: product['id'],
                name: product['name'],
                category: product['category'] ?? "Lainnya",
                price: product['price'],
                stock: newStock,
                token: auth.token ?? '',
              );

              if (context.mounted) {
                if (success) {
                  PremiumSnackbar.showSuccess(context, "Stok berhasil ditambahkan");
                } else {
                  PremiumSnackbar.showError(context, "Gagal menambah stok");
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.primaryOrange),
            child: Text("Simpan", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
```

### 2. `lib/features/admin/product_admin/screens/add_product_screen.dart`
Halaman untuk menambah atau mengubah informasi produk dengan pemilih gambar (*Image Picker*).

```dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // ✅ Import image_picker

import '../providers/admin_product_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/utils/premium_snackbar.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProduct;
  const AddProductScreen({super.key, this.initialProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedCategory;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _nameController.text = widget.initialProduct!['name'] ?? '';
      _priceController.text = (widget.initialProduct!['price'] ?? 0).toString();
      _stockController.text = (widget.initialProduct!['stock'] ?? 0).toString();
      _descController.text = widget.initialProduct!['description'] ?? '';
      _selectedCategory = widget.initialProduct!['category'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar("Gagal mengambil gambar: $e");
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        _showSnackBar("Pilih kategori terlebih dahulu!");
        return;
      }
      if (_imageFile == null && widget.initialProduct == null) {
        _showSnackBar("Pilih gambar produk terlebih dahulu!");
        return;
      }

      final provider = Provider.of<AdminProductProvider>(
        context,
        listen: false,
      );
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token ?? '';

      final navigator = Navigator.of(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: context.colors.primaryOrange),
        ),
      );

      bool success;
      if (widget.initialProduct != null) {
        success = await provider.updateProduct(
          id: widget.initialProduct!['id'],
          name: _nameController.text,
          category: _selectedCategory!,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          description: _descController.text,
          token: token,
          imageFile: _imageFile, 
        );
      } else {
        success = await provider.addProduct(
          name: _nameController.text,
          category: _selectedCategory!,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          description: _descController.text,
          token: token,
          imageFile: _imageFile,
        );
      }

      if (!mounted) return;
      navigator.pop(); // Tutup loading

      if (success) {
        PremiumSnackbar.showSuccess(
          context,
          widget.initialProduct != null
              ? "Produk berhasil diperbarui"
              : "Produk berhasil ditambahkan",
        );
        navigator.pop();
      } else {
        PremiumSnackbar.showError(context, provider.errorMessage ?? "Gagal menyimpan produk");
      }
    }
  }

  void _showSnackBar(String message) {
    if (message.contains("berhasil")) {
      PremiumSnackbar.showSuccess(context, message.replaceAll("✅ ", ""));
    } else {
      PremiumSnackbar.showError(context, message.replaceAll("❌ ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel("Gambar Produk"),
                    _buildUploadArea(), 
                    SizedBox(height: 32),

                    _buildInputLabel("Nama Produk"),
                    _buildPillTextField(
                      controller: _nameController,
                      hint: "Contoh: Roti Keju",
                    ),
                    SizedBox(height: 24),

                    _buildInputLabel("Category"),
                    _buildPillDropdown(), 
                    SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel("Harga (Rp)"),
                              _buildPillTextField(
                                controller: _priceController,
                                hint: "0",
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel("Jumlah Stok"),
                              _buildPillTextField(
                                controller: _stockController,
                                hint: "0",
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    _buildInputLabel("Deskripsi"),
                    _buildDescriptionField(controller: _descController),
                    SizedBox(height: 32),

                    _buildSaveButton(),
                    SizedBox(height: 16),
                    _buildBackButton(),
                    SizedBox(height: 128),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(72),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AppBar(
            backgroundColor: context.colors.bgColor.withValues(alpha: 0.8),
            elevation: 0,
            automaticallyImplyLeading: false,
            shape: Border(
              bottom: BorderSide(
                color: context.colors.primaryOrange.withValues(alpha: 0.1),
              ),
            ),
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.colors.primaryOrange,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.initialProduct != null
                          ? "Edit Produk"
                          : "Tambah Produk",
                      style: GoogleFonts.plusJakartaSans(
                        color: context.colors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Consumer<ThemeProvider>(
                  builder: (context, theme, _) => IconButton(
                    icon: Icon(
                      theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: context.colors.textDark,
                      size: 20,
                    ),
                    onPressed: () => theme.toggleTheme(!theme.isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: context.colors.textGrey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: context.colors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      onTap: _pickImage, 
      borderRadius: BorderRadius.circular(48),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: _imageFile == null ? 52 : 0,
        ), 
        decoration: BoxDecoration(
          color: context.colors.primaryOrange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(48),
          border: Border.all(
            color: context.colors.primaryOrange.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        clipBehavior: Clip.hardEdge, 
        child: _imageFile == null
            ? Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: context.colors.primaryOrange,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Unggah Gambar Produk",
                    style: GoogleFonts.plusJakartaSans(
                      color: context.colors.primaryOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Format yang didukung: JPG, PNG. Ukuran maksimum 2MB",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: context.colors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : kIsWeb
            ? Image.network(
                _imageFile!.path,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              )
            : Image.file(
                File(_imageFile!.path),
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: context.colors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: context.colors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: context.colors.textHint,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Wajib diisi" : null,
      ),
    );
  }

  Widget _buildPillDropdown() {
    final List<String> categories = [
      "Roti",
      "Biskuit",
      "Snack",
    ];

    if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: context.colors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text(
            "Pilih Kategori",
            style: GoogleFonts.plusJakartaSans(color: context.colors.textHint),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
          items: ["Roti", "Biskuit", "Snack"].map(
            (String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: context.colors.textDark,
                  ),
                ),
              );
            },
          ).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildDescriptionField({required TextEditingController controller}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        style: GoogleFonts.plusJakartaSans(fontSize: 16),
        decoration: InputDecoration(
          hintText: "Ceritakan kepada kami tentang produk ini...",
          hintStyle: GoogleFonts.plusJakartaSans(
            color: context.colors.textHint,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _submitData,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: context.colors.primaryOrange,
          borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: context.colors.primaryOrange.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Simpan Produk",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: Text(
            "Kembali",
            style: GoogleFonts.plusJakartaSans(
              color: context.colors.textGrey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
```

### 3. `lib/features/admin/product_admin/providers/admin_product_provider.dart`
State management untuk fungsi penambahan, pembaruan, dan penghapusan produk roti.

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_service.dart';

class AdminProductProvider extends ChangeNotifier {
  List<dynamic> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = "";
  int _selectedTab = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTab => _selectedTab;

  String get _baseUrl => ApiService.baseDomain;
  String get _apiUrl => ApiService.foods;

  List<dynamic> get filteredProducts {
    var list = _allProducts.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (_selectedTab == 1) {
      list = list.where((p) => (p['stock'] ?? 0) == 0).toList();
    } else if (_selectedTab == 2) {
      list = list.where((p) => (p['stock'] ?? 0) > 0 && (p['stock'] ?? 0) <= 15).toList();
      list.sort((a, b) => (a['stock'] ?? 0).compareTo(b['stock'] ?? 0));
    }
    
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners(); 
  }

  void setTab(int index) {
    _selectedTab = index;
    notifyListeners(); 
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> rawProducts = data['data'] ?? [];

        _allProducts = rawProducts.map((p) {
          String rawImage = p['image_url'] ?? '';
          
          if (rawImage.isNotEmpty && !rawImage.startsWith('http') && !rawImage.startsWith('data:image')) {
            if (!rawImage.startsWith('/static')) {
              if (!rawImage.startsWith('/')) rawImage = '/$rawImage';
              p['image_url'] = '$_baseUrl/static$rawImage';
            } else {
              p['image_url'] = '$_baseUrl$rawImage';
            }
          }
          return p;
        }).toList();

      } else {
        _errorMessage = "Gagal memuat produk. Kode: ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = "Gagal terhubung ke server.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct({
    required int id,
    required String name,
    required String category,
    required int price,
    required int stock,
    required String token,
    String? description,
    XFile? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/api/admin/foods/$id'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();
      if (description != null) request.fields['description'] = description;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await fetchProducts();
        return true;
      } else {
        _errorMessage = "Gagal update: ${response.body}";
        return false;
      }
    } catch (e) {
      _errorMessage = "Terjadi kesalahan koneksi.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(int id, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/admin/foods/$id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        await fetchProducts();
        return true;
      } else {
        _errorMessage = "Gagal hapus: ${response.body}";
        return false;
      }
    } catch (e) {
      _errorMessage = "Terjadi kesalahan koneksi.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct({
    required String name,
    required String category,
    required int price,
    required int stock,
    required String token,
    String? description,
    XFile? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/admin/foods'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();
      if (description != null) request.fields['description'] = description;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchProducts();
        return true;
      } else {
        _errorMessage = "Gagal simpan: ${response.body}";
        return false;
      }
    } catch (e) {
      _errorMessage = "Terjadi kesalahan koneksi.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 🏠 PB-05 (Beranda & Katalog Pelanggan)

### 1. `lib/features/home/screens/home_screen.dart`
Tampilan beranda katalog roti bagi pelanggan (dilengkapi filter & pencarian).

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../product/providers/product_provider.dart';

import '../../../core/widgets/staggered_fade_animation.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_promo_banner.dart';
import '../widgets/home_section_header.dart';
import '../widgets/bestseller_card.dart';
import '../widgets/new_menu_card.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_search_results.dart';
import '../widgets/home_filter_sheet.dart';
import 'package:roti_515/core/theme/app_theme.dart'; 

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToProduct;

  const HomeScreen({super.key, this.onGoToProduct});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';      
  bool _isSearching = false;     
  SortOption _currentSort = SortOption.terlaris; 

  final ScrollController _bestsellerScrollController = ScrollController();

  @override
  void dispose() {
    _bestsellerScrollController.dispose();
    super.dispose();
  }

  void _scrollBestseller(bool right) {
    if (!_bestsellerScrollController.hasClients) return;
    
    final currentOffset = _bestsellerScrollController.offset;
    final targetOffset = right 
        ? currentOffset + 186 * 2
        : currentOffset - 186 * 2;
        
    _bestsellerScrollController.animateTo(
      targetOffset.clamp(0.0, _bestsellerScrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    Future.microtask(() => productProvider.fetchProducts());
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    setState(() {
      _searchQuery = trimmed;
      _isSearching = trimmed.isNotEmpty;
    });

    Provider.of<ProductProvider>(context, listen: false)
        .fetchProducts(query: trimmed);
  }

  void _onFilterTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, 
      builder: (_) => HomeFilterSheet(currentSort: _currentSort),
    ).then((result) {
      if (result is SortOption && mounted) {
        setState(() => _currentSort = result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: provider.isLoading && !_isSearching
          ? Center(
              child: CircularProgressIndicator(color: context.colors.primaryOrange),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeAppBar(
                    onSearchChanged: _onSearchChanged,
                    onFilterTap: _onFilterTap,
                  ),

                  if (_isSearching)
                    HomeSearchResults(query: _searchQuery)
                  else ...[
                    SizedBox(height: 10),

                    HomePromoBanner(onPesanSekarang: widget.onGoToProduct),
                    SizedBox(height: 32),

                    HomeSectionHeader(
                      title: "Terlaris",
                      showArrows: true,
                      onLeftArrowTap: () => _scrollBestseller(false),
                      onRightArrowTap: () => _scrollBestseller(true),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        controller: _bestsellerScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: provider.bestsellers.length,
                        itemBuilder: (context, index) {
                          return StaggeredFadeAnimation(
                            index: index,
                            child: BestsellerCard(
                                product: provider.bestsellers[index]),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 32),

                    HomeSectionHeader(
                      title: "Menu Baru",
                      showArrows: false,
                      onSeeAllTap: widget.onGoToProduct,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 106,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: provider.newMenus.length,
                        itemBuilder: (context, index) {
                          return StaggeredFadeAnimation(
                            index: index,
                            child: NewMenuCard(
                                product: provider.newMenus[index]),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 48),

                    HomeFooter(),
                  ],
                ],
              ),
            ),
    );
  }
}
```

### 2. `lib/features/product/providers/product_provider.dart`
State management untuk mendapatkan dan memfilter katalog produk di sisi Pelanggan.

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import '../../../core/network/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortOption = 'bestseller'; 

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get sortOption => _sortOption;

  List<ProductModel> get bestsellers =>
      _products.where((p) => p.isBestseller == true).toList();

  List<ProductModel> get newMenus =>
      _products.where((p) => p.isBestseller == false).toList();

  final String _baseUrl = ApiService.foods;
  final String _staticUrl = ApiService.staticFiles;

  Future<void> fetchProducts({String? query, String? sort}) async {
    _isLoading = true;
    _errorMessage = '';

    if (query != null) {
      _searchQuery = query;
    }
    if (sort != null) {
      _sortOption = sort;
    }

    try {
      final Map<String, String> queryParameters = {};

      if (_selectedCategory != 'All') {
        queryParameters['category'] = _selectedCategory;
      }

      if (_searchQuery.isNotEmpty) {
        queryParameters['search'] = _searchQuery;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
      debugPrint("📡 Memeriksa API: $uri");

      final response = await http.get(uri).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        final List<dynamic> listData = decodedData['data'] ?? [];

        _products = listData.map((json) {
          String fileName = json['image_url'] ?? '';
          if (fileName.isNotEmpty && !fileName.startsWith('http') && !fileName.startsWith('data:image')) {
            json['image_url'] = '$_staticUrl$fileName';
          }
          return ProductModel.fromJson(json);
        }).toList();

        if (_selectedCategory != 'All') {
          _products = _products
              .where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase())
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          _products = _products
              .where((p) =>
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        _applySorting();

        debugPrint("✅ Berhasil memuat ${_products.length} produk.");
      } else {
        _errorMessage = "Gagal memuat data (Status HTTP: ${response.statusCode})";
        debugPrint("❌ Server Error: ${response.body}");
      }
    } catch (e) {
      _errorMessage = "Koneksi ke server gagal. Periksa koneksi backend.";
      debugPrint("❌ Provider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    fetchProducts();
  }

  void setSortOption(String sort) {
    _sortOption = sort;
    _applySorting();
    notifyListeners();
  }

  void _applySorting() {
    switch (_sortOption) {
      case 'bestseller':
        _products.sort((a, b) =>
            (b.isBestseller ? 1 : 0).compareTo(a.isBestseller ? 1 : 0));
        break;
      case 'newest':
        _products.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'price_asc':
        _products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        _products.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _sortOption = 'bestseller';
    fetchProducts();
  }
}
```
