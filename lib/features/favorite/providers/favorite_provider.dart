import 'package:flutter/material.dart';

// --- IMPORT MODEL BARU ---
// Gunakan jalur relatif untuk memanggil ProductModel dari fitur product
import '../../product/models/product_model.dart'; 

class FavoriteProvider extends ChangeNotifier {
  // Ubah tipe data List menjadi ProductModel
  final List<ProductModel> _favoriteItems = [];

  List<ProductModel> get favorites => _favoriteItems;

  // Cek apakah produk sudah difavoritkan
  bool isFavorite(ProductModel product) {
    return _favoriteItems.any((item) => item.id == product.id);
  }

  // Tambah atau Hapus dari favorit
  void toggleFavorite(ProductModel product) {
    final index = _favoriteItems.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _favoriteItems.removeAt(index);
    } else {
      _favoriteItems.add(product);
    }
    notifyListeners();
  }
}
