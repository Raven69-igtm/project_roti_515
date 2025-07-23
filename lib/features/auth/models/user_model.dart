import '../../../core/models/user.dart';


/// Bridge class for existing UserModel code if needed, 
/// but we should preferably use Pelanggan or Admin directly.
/// This file now acts as a container for specialized auth model logic.

class UserModel extends User {
  final String? address;
  final String? photoUrl;
  final DateTime? createdAt;

  UserModel({
    required super.id,
    required super.nama,
    required super.email,
    required super.role,
    this.address,
    this.photoUrl,
    this.createdAt,
    super.password = '',
  });

  // Encapsulation: Getter for backward compatibility
  String get name => nama;
  String? get phone => null; // Overridden in PelangganModel
  String get timeAgo => _calculateTimeAgo();

  String _calculateTimeAgo() {
    if (createdAt == null) return 'Baru';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return 'Sekarang';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }

  @override
  bool login() {
    print('Generic User $nama logging in...');
    return true;
  }

  @override
  void logout() {
    print('User $nama logging out...');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] ?? 'Pelanggan').toString().toLowerCase();
    if (role == 'admin') {
      return AdminModel.fromJson(json);
    } else {
      return PelangganModel.fromJson(json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['address'] = address;
    map['photo_url'] = photoUrl;
    map['created_at'] = createdAt?.toIso8601String();
    return map;
  }
}

class PelangganModel extends UserModel {
  final String? noHp;
  final DateTime? tglDaftar;

  PelangganModel({
    required super.id,
    required super.nama,
    required super.email,
    super.password = '',
    this.noHp,
    this.tglDaftar,
    super.address,
    super.photoUrl,
  }) : super(
          role: 'pelanggan',
          createdAt: tglDaftar,
        );

  @override
  String? get phone => noHp;

  @override
  bool login() {
    print('Pelanggan $nama login via Aplikasi Mobile...');
    // Logika spesifik pelanggan (misal: cek poin reward)
    return true;
  }

  factory PelangganModel.fromJson(Map<String, dynamic> json) {
    return PelangganModel(
      id: json['id'] ?? 0,
      nama: json['name'] ?? '',
      email: json['email'] ?? '',
      noHp: json['phone'] ?? '',
      tglDaftar: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      address: json['address'],
      photoUrl: json['photo_url'],
    );
  }
}

class AdminModel extends UserModel {
  final String level;

  AdminModel({
    required super.id,
    required super.nama,
    required super.email,
    super.password = '',
    required this.level,
  }) : super(
          role: 'admin',
        );

  @override
  bool login() {
    print('Admin $nama login via Portal Admin dengan level $level...');
    // Logika spesifik admin (misal: logging akses sensitif)
    return true;
  }

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] ?? 0,
      nama: json['name'] ?? '',
      email: json['email'] ?? '',
      level: json['role'] ?? 'Admin',
    );
  }
}
