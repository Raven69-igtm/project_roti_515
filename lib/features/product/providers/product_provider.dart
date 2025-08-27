import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import '../../../core/network/api_service.dart';

/// Provider untuk mengelola state data Produk/Katalog.
class ProductProvider extends ChangeNotifier {
  // State variables
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortOption = 'bestseller'; // Sortir aktif: bestseller | newest | price_asc | price_desc
  Timer? _pollingTimer;

  // Getters untuk diakses oleh UI
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get sortOption => _sortOption;

  /// Memfilter produk unggulan (Bestseller)
  List<ProductModel> get bestsellers {
    final list = _products.where((p) => p.isBestseller == true).toList();
    list.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    return list;
  }

  /// Memfilter produk menu baru (Non-Bestseller)
  List<ProductModel> get newMenus =>
      _products.where((p) => p.isBestseller == false).toList();

  // Endpoint konfigurasi dari ApiService terpusat
  final String _baseUrl = ApiService.foods;
  final String _staticUrl = ApiService.staticFiles;

  /// Mengambil data produk dari backend REST API dengan opsi pencarian/filter.
  /// Parameter [sort] mengontrol urutan tampilan secara lokal (client-side).
  Future<void> fetchProducts({String? query, String? sort}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    if (query != null) {
      _searchQuery = query;
    }
    if (sort != null) {
      _sortOption = sort;
    }

    try {
      // Menyusun parameter query untuk URL (opsional: category & search)
      final Map<String, String> queryParameters = {};

      if (_selectedCategory != 'All') {
        queryParameters['category'] = _selectedCategory;
      }

      if (_searchQuery.isNotEmpty) {
        queryParameters['search'] = _searchQuery;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
      debugPrint("📡 Memeriksa API: $uri");

      // Modifikasi timeout 10 detik untuk mencegah aplikasi menggantung (hang)
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);

        // Ekstraksi array JSON dari prop 'data' sesuai format standar response backend
        final List<dynamic> listData = decodedData['data'] ?? [];

        _products = listData.map((json) {
          // Menyesuaikan path gambar relatif dari database menjadi absolute URL static files
          String fileName = json['image_url'] ?? '';
          if (fileName.isNotEmpty && !fileName.startsWith('http') && !fileName.startsWith('data:image')) {
            json['image_url'] = '$_staticUrl$fileName';
          }
          return ProductModel.fromJson(json);
        }).toList();

        // ++ Filter lokal jika backend tidak menyaring dengan benar ++
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

        // Sorting secara lokal (client-side) agar tidak perlu ubah backend
        _applySorting();

        debugPrint("✅ Berhasil memuat ${_products.length} produk.");
      } else {
        // Penanganan jika server mengembalikan HTTP Error (misal 500 / 404)
        _errorMessage = "Gagal memuat data (Status HTTP: ${response.statusCode})";
        debugPrint("❌ Server Error: ${response.body}");
      }
    } catch (e) {
      // Penanganan error network / putus koneksi
      _errorMessage = "Koneksi ke server gagal. Periksa koneksi backend.";
      debugPrint("❌ Provider Error: $e");
    } finally {
      // Menghentikan state loading dan meminta UI untuk merender ulang perubahan state
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memulai polling otomatis di latar belakang setiap 10 detik.
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isLoading) {
        _fetchProductsSilent();
      }
    });
  }

  /// Menghentikan polling otomatis.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh produk diam-diam di latar belakang (tanpa loader fullscreen).
  Future<void> _fetchProductsSilent() async {
    try {
      final Map<String, String> queryParameters = {};

      if (_selectedCategory != 'All') {
        queryParameters['category'] = _selectedCategory;
      }

      if (_searchQuery.isNotEmpty) {
        queryParameters['search'] = _searchQuery;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        final List<dynamic> listData = decodedData['data'] ?? [];

        final List<ProductModel> updatedProducts = listData.map((json) {
          String fileName = json['image_url'] ?? '';
          if (fileName.isNotEmpty && !fileName.startsWith('http') && !fileName.startsWith('data:image')) {
            json['image_url'] = '$_staticUrl$fileName';
          }
          return ProductModel.fromJson(json);
        }).toList();

        var list = updatedProducts;
        if (_selectedCategory != 'All') {
          list = list
              .where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase())
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          list = list
              .where((p) =>
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        _products = list;
        _applySorting();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Silent polling error: $e");
    }
  }

  /// Memperbarui kategori produk yang sedang aktif dan menjalankan ulang request API.
  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    fetchProducts();
  }

  /// Mengubah opsi sortir dan memperbarui tampilan produk.
  void setSortOption(String sort) {
    _sortOption = sort;
    _applySorting();
    notifyListeners();
  }

  /// Sorting lokal berdasarkan _sortOption yang aktif.
  void _applySorting() {
    switch (_sortOption) {
      case 'bestseller':
        // Tampilkan bestseller di atas, lalu urutkan berdasarkan soldCount teratas
        _products.sort((a, b) {
          int cmp = (b.isBestseller ? 1 : 0).compareTo(a.isBestseller ? 1 : 0);
          if (cmp != 0) return cmp;
          return b.soldCount.compareTo(a.soldCount);
        });
        break;
      case 'newest':
        // Urutkan berdasarkan ID descending (ID terbesar = paling baru)
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

  /// Membersihkan seluruh filter pencarian & kategori ke posisi awal.
  void clearFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _sortOption = 'bestseller';
    fetchProducts();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
