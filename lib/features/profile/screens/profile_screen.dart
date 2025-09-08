import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // Package untuk melakukan HTTP request ke Backend API
import 'package:provider/provider.dart'; // Package untuk manajemen state, digunakan untuk mengambil data autentikasi

// --- IMPORT COMPONENT WIDGETS ---
// Mengimpor widget-widget kecil yang sudah dipisahkan untuk menjaga kode tetap bersih (modular)
import '../widgets/profile_top_nav_bar.dart'; // Widget bar navigasi atas khusus profil
import '../widgets/profile_header.dart'; // Widget untuk bagian header (avatar, nama, email)
import '../widgets/profile_section_label.dart'; // Widget untuk label pemisah kategori menu
import '../widgets/profile_menu_tile.dart'; // Widget untuk satu baris item menu profil
import '../widgets/profile_logout_button.dart'; // Widget tombol logout dengan gaya khusus
import 'address_management_screen.dart'; // Halaman manajemen alamat
import 'settings_screen.dart'; // Halaman pengaturan
import '../../../presentation/pages/profile/edit_profile_page.dart'; // Halaman edit profil

// --- IMPORT PONDASI ---
// Konstanta warna tema aplikasi
import '../../auth/providers/auth_provider.dart'; // Provider untuk akses token & data user login
import '../../../core/network/api_service.dart'; // Service pusat untuk URL/Endpoint API
import '../../../presentation/pages/profile/order_history_page.dart'; // Halaman riwayat pesanan pelanggan
import 'package:roti_515/core/theme/app_theme.dart'; // Untuk menentukan media type file upload

/// Layar utama Profil Pengguna.
/// Menggunakan StatefulWidget karena layar ini perlu mengambil data dari server dan memperbarui UI.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variable Map untuk menampung data user yang didapat dari API (name, email, address, dll)
  Map<String, dynamic>? _userData;

  // Flag indikator loading; True saat sedang mengambil data, False jika sudah selesai/gagal
  bool _isLoading = true;

  // Mengambil URL endpoint profile dari ApiService agar mudah dikelola jika domain berubah
  final String _apiUrl = ApiService.profile;

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi fetch data sesaat setelah halaman pertama kali dibuat (diinisialisasi)
    _fetchProfile();
  }

  /// Fungsi untuk mengambil data profil user dari Backend.
  Future<void> _fetchProfile() async {
    try {
      // Mengambil token JWT dari AuthProvider untuk ditaruh di Header (Autentikasi Bearer)
      final token = Provider.of<AuthProvider>(context, listen: false).token;

      // Mengirimkan permintaan GET ke API Profile
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Bearer $token", // Mengirimkan token bukti login valid
        },
      );

      // Jika response dari server adalah 200 (OK/Berhasil)
      if (response.statusCode == 200) {
        // Mendecode string JSON dari server menjadi Map objek Dart
        final data = jsonDecode(response.body);

        // Memastikan widget masih aktif (tidak di-close oleh user saat loading) sebelum update UI
        if (mounted) {
          final user = data['user'];
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          // Update global photoUrl di AuthProvider agar AppBar sinkron
          authProvider.updatePhotoUrl(user['photo_url']);

          // Inject data lokal (address/name/phone) karena API mungkin tidak menyimpannya
          if (authProvider.address != null &&
              authProvider.address!.isNotEmpty) {
            user['address'] = authProvider.address;
          }
          if (authProvider.name != null && authProvider.name!.isNotEmpty) {
            user['name'] = authProvider.name;
          }
          if (authProvider.phone != null && authProvider.phone!.isNotEmpty) {
            user['phone'] = authProvider.phone;
          }

          setState(() {
            _userData = user; // Menyimpan data 'user' ke variable lokal
            _isLoading = false; // Menandakan proses loading telah selesai
          });
        }
      } else {
        // Jika server mengembalikan error (misal 401 atau 500), matikan indicator loading
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      // Menangani error jika terjadi kesalahan koneksi internet atau crash saat parsing
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menyiapkan data nama dan email untuk ditampilkan di UI.
    // Jika data belum ada atau kosong, tampilkan teks default
    String fullName = (_userData?['name'] ?? "").toString();
    if (fullName.isEmpty) fullName = "Pengguna Roti 515";
    String email = _userData?['email'] ?? "memuat..";

    return Scaffold(
      // Mengatur warna latar belakang halaman menggunakan tema dari AppColors
      backgroundColor: context.colors.bgColor,

      // Menggunakan logika percabangan untuk tampilan utama
      body: _isLoading
          // 1. Jika masih loading, tampilkan indikator lingkaran berputar di tengah layar
          ? Center(
              child: CircularProgressIndicator(
                color: context.colors.primaryOrange,
              ),
            )
          // 2. Jika sudah selesai loading, tampilkan konten profil sesungguhnya
          : SafeArea(
              // SafeArea memastikan konten tidak tertutup oleh notch atau status bar HP
              child: SingleChildScrollView(
                // SingleChildScrollView memungkinkan konten bisa di-scroll jika layar kecil
                child: Column(
                  children: [
                    // --- 1. BAR NAVIGASI ATAS ---
                    // Menampilkan header statis dengan tulisan "Profil"
                    ProfileTopNavBar(),

                    // --- 2. INFORMASI USER (AVATAR & NAMA) ---
                    // Komponen yang menampilkan gambar avatar, nama lengkap, dan email user
                    ProfileHeader(
                      name: fullName,
                      email: email,
                      photoUrl: _userData?['photo_url'],
                    ),

                    // Memberikan jarak vertikal antar elemen
                    SizedBox(height: 24),

                    // --- 3. KATEGORI: AKTIVITAS AKUN ---
                    ProfileSectionLabel(label: "Aktivitas Akun"),

                    // Tombol Menu: Edit Profil
                    ProfileMenuTile(
                      icon: Icons.edit_rounded,
                      title: "Edit Profil",
                      subtitle: "Ubah nama, telepon & password",
                      onTap: () async {
                        if (_userData == null) return;
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfilePage(userData: _userData!),
                          ),
                        );
                        // Refresh profil jika ada perubahan
                        if (updated == true && mounted) {
                          _fetchProfile();
                        }
                      },
                    ),

                    // Tombol Menu: Riwayat Pesanan
                    ProfileMenuTile(
                      icon: Icons.receipt_long_rounded, // Icon struk/order
                      title: "Riwayat Pesanan", // Judul menu
                      onTap: () {
                        // Navigasi pindah ke halaman OrderHistoryPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderHistoryPage(),
                          ),
                        );
                      },
                    ),

                    // Tombol Menu: Alamat Lengkap
                    ProfileMenuTile(
                      icon: Icons.location_on_rounded, // Icon lokasi map
                      title: "Alamat Lengkap",
                      // Subtitle dinamis: Menampilkan alamat jika ada, atau teks instruksi jika kosong
                      subtitle:
                          (_userData?['address'] as String? ?? "").isNotEmpty
                          ? _userData!['address']
                          : "Tambahkan / Ubah",
                      onTap: () async {
                        // Menunggu hasil kembalian (alamat baru) dari halaman AddressManagementScreen
                        final newAddress = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressManagementScreen(
                              currentAddress:
                                  _userData?['address'] ?? "Ambil Di Toko",
                            ),
                          ),
                        );

                        // Jika ada alamat baru yang dikembalikan, update UI lokal
                        if (newAddress != null && mounted) {
                          setState(() {
                            _userData?['address'] = newAddress;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 24),

                    // --- 4. KATEGORI: PREFERENSI ---
                    ProfileSectionLabel(label: "Preferensi"),

                    // Tombol Menu: Pengaturan (Saat ini masih statis/kosong)
                    ProfileMenuTile(
                      icon: Icons.settings_rounded,
                      title: "Pengaturan Utama",
                      subtitle: "Notifikasi, Privasi",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 32),

                    // --- 5. AREA TOMBOL LOGOUT ---
                    // Widget khusus yang menangani proses keluar akun (Logout)
                    ProfileLogoutButton(),

                    // Memberikan padding/jarak bawah yang cukup agar tidak terpotong Navbar utama
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}
