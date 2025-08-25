import '../../../core/network/api_service.dart';
import '../../../core/models/produk.dart';

class ProductModel extends Produk {
  final String description;
  final double rating;
  final String category;
  final bool isBestseller;
  final int soldCount;

  ProductModel({
    required super.id,
    required super.nama,
    required this.description,
    required super.harga,
    required super.gambar,
    required this.rating,
    required this.category,
    required this.isBestseller,
    required super.stok,
    required this.soldCount,
  });

  // Getters for OOP Encapsulation (nama and harga are inherited)
  String get name => nama;
  int get price => harga;
  String get imageUrl => gambar;
  int get stock => stok;

  // Factory untuk mengonversi JSON dari API menjadi objek ProductModel
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      nama: json['name'] ?? '',
      description: json['description'] ?? '',
      harga: (json['price'] ?? 0).toInt(),
      gambar: _resolveImageUrl(json['image_url']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      isBestseller: json['is_bestseller'] ?? false,
      stok: json['stock'] ?? 0,
      soldCount: json['sold_count'] ?? 0,
    );
  }

  /// Resolusi URL gambar: mendukung Base64 data URL, URL penuh, dan nama file biasa.
  static String _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    // Jika sudah base64 data URL, gunakan langsung
    if (raw.startsWith('data:image')) return raw;
    // Delegasikan ke ApiService untuk URL/path biasa
    return ApiService.getDisplayImage(raw);
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nama,
      'description': description,
      'price': harga,
      'image_url': gambar,
      'rating': rating,
      'category': category,
      'is_bestseller': isBestseller,
      'stock': stok,
      'sold_count': soldCount,
    };
  }
}
