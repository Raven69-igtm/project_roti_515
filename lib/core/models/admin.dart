import 'user.dart';
import 'produk.dart';
import 'jadwal_ambil.dart';
import 'order.dart';

class Admin extends User {
  String _level;

  Admin({
    required super.id,
    required super.nama,
    required super.email,
    required super.role,
    String password = '',
    required String level,
  }) : _level = level;

  // Encapsulation: Getter
  String get level => _level;

  // Polymorphism: Override login
  @override
  bool login() {
    print('Admin $nama ($level) logging in...');
    return true;
  }

  @override
  void logout() {
    print('Admin $nama logging out...');
  }

  void tambahProduk(Produk produk) {
    print('Admin $nama menambah produk: ${produk.nama}');
  }

  void editProduk(Produk produk) {
    print('Admin $nama mengedit produk: ${produk.nama}');
  }

  void hapusProduk(int id) {
    print('Admin $nama menghapus produk ID: $id');
  }

  void aturJamAmbil(JadwalAmbil jadwal) {
    print('Admin $nama mengatur jam ambil: ${jadwal.id}');
  }

  void kelolaOrder(Order order) {
    print('Admin $nama mengelola order: ${order.id}');
  }

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? 0,
      nama: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      password: '',
      level: json['role'] ?? 'admin',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['role'] = _level;
    return map;
  }
}
