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
