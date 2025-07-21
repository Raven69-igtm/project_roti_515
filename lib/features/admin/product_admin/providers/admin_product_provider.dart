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
  String _selectedCategory = "All";

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTab => _selectedTab;
  List<dynamic> get allProducts => _allProducts;
  String get selectedCategory => _selectedCategory;

  String get _baseUrl => ApiService.baseDomain;
  String get _apiUrl => ApiService.foods;

  List<dynamic> get filteredProducts {
    var list = _allProducts.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(_searchQuery);
      
      final productCategory = (p['category'] ?? '').toString().toLowerCase();
      final matchesCategory = _selectedCategory.toLowerCase() == 'all' || 
                              productCategory == _selectedCategory.toLowerCase();
      
      return matchesSearch && matchesCategory;
    }).toList();

    if (_selectedTab == 1) {
      list = list.where((p) => (p['stock'] ?? 0) == 0).toList();
    } else if (_selectedTab == 2) {
      list = list.where((p) => (p['stock'] ?? 0) > 0 && (p['stock'] ?? 0) <= 15).toList();
      // Mengurutkan dari stok terkecil
      list.sort((a, b) => (a['stock'] ?? 0).compareTo(b['stock'] ?? 0));
    }
    
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners(); 
  }

  void setCategory(String category) {
    _selectedCategory = category;
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
          // 1. Ambil nama file dari DB (contoh: "onde_onde.png")
          String rawImage = p['image_url'] ?? '';
          
          if (rawImage.isNotEmpty && !rawImage.startsWith('http') && !rawImage.startsWith('data:image')) {
            // 2. Jika di DB belum ada kata "/static", kita tambahkan manual
            if (!rawImage.startsWith('/static')) {
              // Pastikan path diawali '/'
              if (!rawImage.startsWith('/')) rawImage = '/$rawImage';
              
              // HASIL: http://localhost:8080/static/onde_onde.png
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

  // --- FUNGSI UPDATE PRODUK ---
  Future<bool> updateProduct({
    required int id,
    required String name,
    required String category,
    required int price,
    required int stock,
    required String token,
    String? description,
    XFile? imageFile, // file gambar baru (opsional)
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

      // Lampirkan file gambar baru jika ada
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

  // --- FUNGSI HAPUS PRODUK ---
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

  // --- FUNGSI TAMBAH PRODUK ---
  Future<bool> addProduct({
    required String name,
    required String category,
    required int price,
    required int stock,
    required String token,
    String? description,
    XFile? imageFile, // file gambar wajib untuk produk baru
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

      // Lampirkan file gambar
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
