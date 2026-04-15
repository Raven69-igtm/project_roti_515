import 'user.dart';
import 'keranjang.dart';
import 'order.dart';

class Pelanggan extends User {
  String _noHp;
  DateTime _tglDaftar;

  Pelanggan({
    required super.id,
    required super.nama,
    required super.email,
    required super.role,
    String password = '',
    required String noHp,
    required DateTime tglDaftar,
  })  : _noHp = noHp,
        _tglDaftar = tglDaftar;

  // Encapsulation: Getters
  String get noHp => _noHp;
  DateTime get tglDaftar => _tglDaftar;

  // Polymorphism: Override login
  @override
  bool login() {
    print('Pelanggan $nama logging in...');
    return true;
  }

  @override
  void logout() {
    print('Pelanggan $nama logging out...');
  }

  bool daftar() {
    print('Pelanggan $nama mendaftar...');
    return true;
  }

  Order pesanProduk() {
    print('Pelanggan $nama memesan produk...');
    // Implementation placeholder
    return Order(id: 1, status: 'pending', total: 0, jamAmbil: '10:00', metodeBayar: 'Cash');
  }

  Keranjang lihatKeranjang() {
    print('Pelanggan $nama melihat keranjang...');
    // Implementation placeholder
    return Keranjang(id: 1, pelangganId: id, items: []);
  }

  factory Pelanggan.fromJson(Map<String, dynamic> json) {
    return Pelanggan(
      id: json['id'] ?? 0,
      nama: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'pelanggan',
      password: '', // Password usually not returned from API
      noHp: json['phone'] ?? '',
      tglDaftar: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['phone'] = _noHp;
    map['created_at'] = _tglDaftar.toIso8601String();
    return map;
  }
}
