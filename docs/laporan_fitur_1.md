Laporan Fitur 1 (PB-01 & PB-02 - Autentikasi)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

a) Fitur 1: Autentikasi (Sistem Login & Logout untuk Admin dan Pelanggan)

1. Deskripsi Fitur
Fitur Autentikasi mencakup mekanisme masuk (login) dan keluar (logout) dari aplikasi untuk dua kategori pengguna: Pelanggan dan Admin. Fitur ini memverifikasi identitas pengguna menggunakan kredensial berupa email/nama pengguna dan kata sandi yang dikirimkan ke REST API backend. Sistem secara otomatis membaca peran (role) pengguna untuk menentukan halaman navigasi berikutnya (Admin diarahkan ke Dashboard Admin, sedangkan Pelanggan ke katalog Beranda Pelanggan).

2. Implementasi Teknis & Alur Kerja
* State Management (Provider): Aplikasi menggunakan AuthProvider untuk melacak status masuk (isLoggedIn), data profil (nama, foto), dan peran pengguna (role).
* Penyimpanan Sesi (Shared Preferences): Token JWT (JSON Web Token) yang didapat dari server disimpan di memori HP secara permanen. Hal ini mendukung kemampuan auto-login saat aplikasi pertama kali dibuka.
* Validasi Keamanan: Menggunakan SafeArea dan SingleChildScrollView untuk menjamin tampilan form tetap responsif ketika keyboard virtual HP muncul.

3. Kode Sumber Lengkap (Full Source Code)

```dart
import 'dart:convert'; // Untuk melakukan encoding/decoding JSON saat mengirim data ke API
import 'package:flutter/material.dart'; // Library utama Flutter untuk membangun antarmuka pengguna (UI)
import 'package:http/http.dart' as http; // Digunakan untuk melakukan HTTP request (GET, POST, dll) ke backend
import 'package:google_fonts/google_fonts.dart'; // Library untuk menggunakan font Google secara langsung

import '../../../core/utils/premium_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../../../core/network/api_service.dart';

import '../widgets/login_logo.dart';
import '../widgets/login_tab_selector.dart';
import '../widgets/login_input_field.dart';
import '../widgets/login_button.dart';
import '../widgets/login_footer.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
      
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late TabController _tabController;

  bool _isLoading = false;
  bool _isObscure = true;

  String get _apiUrl => ApiService.login;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      PremiumSnackbar.showError(context, "Email dan Password wajib diisi");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({
          "email": _emailController.text.trim(), 
          "password": _passwordController.text, 
        }),
      ).timeout(Duration(seconds: 10)); 

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && mounted) {
        final String token = data['token'];
        final String userRole = data['user']['role'];
        final String userName = data['user']['name'];
        final String? photoUrl = data['user']['photo_url'];

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
        PremiumSnackbar.showError(context, data['error'] ?? "Gagal login");
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, "Gagal terhubung ke server. Cek koneksi.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.authBackground, 
      body: SafeArea( 
        child: SingleChildScrollView( 
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), 
          child: Column( 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LoginLogo(),
              SizedBox(height: 32),
              
              LoginTabSelector(controller: _tabController),
              SizedBox(height: 32),
              
              LoginInputField(
                controller: _emailController,
                label: "Email",
                hint: "Masukkan Email Atau Nama Pengguna",
                icon: Icons.mail_outline_rounded,
              ),
              SizedBox(height: 20),
              
              LoginInputField(
                controller: _passwordController,
                label: "Password",
                hint: "Masukkan Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true, 
                obscureText: _isObscure, 
                onSuffixTap: () => setState(() => _isObscure = !_isObscure), 
              ),

              if (_tabController.index == 0) 
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

              LoginButton(isLoading: _isLoading, onPressed: _login),
              SizedBox(height: 32),

              if (_tabController.index == 0)
                LoginFooter(),
              
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}
```

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  String? _name;
  String? _photoUrl;
  String? _address; 
  String? _phone;   

  String? get token => _token;
  String? get role => _role;
  String? get name => _name;
  String? get photoUrl => _photoUrl;
  String? get address => _address;
  String? get phone => _phone;

  bool get isLoggedIn => _token != null;
  bool get isAdmin => _role == 'admin';

  static final String _keyToken = "auth_token";
  static final String _keyRole = "user_role";
  static final String _keyName = "user_name";
  static final String _keyPhotoUrl = "user_photo_url";
  static final String _keyAddress = "user_address";
  static final String _keyPhone = "user_phone";

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _role = prefs.getString(_keyRole);
    _name = prefs.getString(_keyName);
    _photoUrl = prefs.getString(_keyPhotoUrl);
    _address = prefs.getString(_keyAddress);
    _phone = prefs.getString(_keyPhone);
    
    notifyListeners();
  }

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

  Future<void> login(String newToken, {String? role, String? name, String? photoUrl}) async {
    _token = newToken;
    _role = role;
    _name = name;
    _photoUrl = photoUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, newToken);
    if (role != null) await prefs.setString(_keyRole, role);
    if (name != null) await prefs.setString(_keyName, name);
    if (photoUrl != null) await prefs.setString(_keyPhotoUrl, photoUrl);

    notifyListeners();
  }

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

    notifyListeners();
  }
}
```
