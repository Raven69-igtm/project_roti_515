Laporan Fitur 4 (PB-05 - Beranda Pelanggan)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

d) Fitur 4: Beranda Pelanggan (Antarmuka Katalog Produk Utama bagi Pengguna Akhir)

1. Deskripsi Fitur
Fitur Beranda Pelanggan dirancang khusus untuk memanjakan pengguna akhir (pelanggan) saat menjelajahi katalog produk roti yang ditawarkan. Halaman utama ini dilengkapi dengan bar navigasi atas yang bersih, banner promosi dinamis yang interaktif, daftar menu terlaris (bestsellers), serta menu baru yang segar. Pengguna juga dapat melakukan pencarian produk secara langsung menggunakan kolom pencarian dan mengurutkan atau menyaring produk lewat bottom sheet filter.

2. Implementasi Teknis & Alur Kerja
* Client-side Sorting & Filtering: Memproses pengurutan (terlaris, menu baru, harga terendah, harga tertinggi) secara lokal di sisi aplikasi menggunakan product_provider.dart untuk memberikan respons antarmuka yang instan tanpa membebani server backend.
* Efek Transisi & Animasi Visual: Menyematkan animasi masuk bertingkat (Staggered Fade Animation) pada item kartu produk untuk menciptakan impresi antarmuka yang premium.
* Dynamic Image Loader: Memanfaatkan parser URL dinamis yang mengubah path gambar statis relatif dari database menjadi URL gambar absolut siap pakai.

3. Kode Sumber Lengkap (Full Source Code)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../product/providers/product_provider.dart';

import '../../../core/widgets/staggered_fade_animation.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_promo_banner.dart';
import '../widgets/home_section_header.dart';
import '../widgets/bestseller_card.dart';
import '../widgets/new_menu_card.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_search_results.dart'; // Widget hasil pencarian
import '../widgets/home_filter_sheet.dart';
import 'package:roti_515/core/theme/app_theme.dart';   // Bottom sheet filter

/// Layar Beranda (Home).
/// Kini mendukung fitur pencarian menu dan filter Bottom Sheet.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToProduct;

  const HomeScreen({super.key, this.onGoToProduct});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';      // Query ketikan user saat ini
  bool _isSearching = false;     // Flag: apakah user sedang mencari?
  SortOption _currentSort = SortOption.terlaris; // Sortir aktif

  // Controller untuk horizontal list bestseller
  final ScrollController _bestsellerScrollController = ScrollController();

  @override
  void dispose() {
    _bestsellerScrollController.dispose();
    super.dispose();
  }

  // Fungsi scroll kiri/kanan untuk bestseller
  void _scrollBestseller(bool right) {
    if (!_bestsellerScrollController.hasClients) return;
    
    // Asumsi: lebar card (170) + margin (16) = 186
    // Kita scroll 2 item (186 * 2) setiap klik
    final currentOffset = _bestsellerScrollController.offset;
    final targetOffset = right 
        ? currentOffset + 186 * 2
        : currentOffset - 186 * 2;
        
    _bestsellerScrollController.animateTo(
      targetOffset.clamp(0.0, _bestsellerScrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    // Ambil data produk saat layar pertama dibuka
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    Future.microtask(() => productProvider.fetchProducts());
  }

  /// Dipanggil saat user mengetik di search bar.
  /// Sudah di-debounce dari HomeAppBar, jadi langsung pakai query-nya.
  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    setState(() {
      _searchQuery = trimmed;
      _isSearching = trimmed.isNotEmpty;
    });

    // Minta provider fetch produk sesuai query
    Provider.of<ProductProvider>(context, listen: false)
        .fetchProducts(query: trimmed);
  }

  /// Dipanggil saat user men-tap ikon filter (tune).
  void _onFilterTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Agar bottom sheet bisa memanjang secara penuh
      builder: (_) => HomeFilterSheet(currentSort: _currentSort),
    ).then((result) {
      // Simpan sort option yang dikembalikan dari bottom sheet
      if (result is SortOption && mounted) {
        setState(() => _currentSort = result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: provider.isLoading && !_isSearching
          // Loading awal (bukan saat search) — spinner terpusat
          ? Center(
              child: CircularProgressIndicator(color: context.colors.primaryOrange),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. APP BAR (dengan search yang sudah fungsional) ──
                  HomeAppBar(
                    onSearchChanged: _onSearchChanged,
                    onFilterTap: _onFilterTap,
                  ),

                  // ── 2. KONTEN: hasil pencarian ATAU tampilan home normal ──
                  if (_isSearching)
                    // Tampilkan grid hasil pencarian
                    HomeSearchResults(query: _searchQuery)
                  else ...[
                    // Tampilan home normal
                    SizedBox(height: 10),

                    // Banner promo
                    HomePromoBanner(onPesanSekarang: widget.onGoToProduct),
                    SizedBox(height: 32),

                    // Bestsellers
                    HomeSectionHeader(
                      title: "Terlaris",
                      showArrows: true,
                      onLeftArrowTap: () => _scrollBestseller(false),
                      onRightArrowTap: () => _scrollBestseller(true),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        controller: _bestsellerScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: provider.bestsellers.length,
                        itemBuilder: (context, index) {
                          return StaggeredFadeAnimation(
                            index: index,
                            child: BestsellerCard(
                                product: provider.bestsellers[index]),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 32),

                    // Menu Baru
                    HomeSectionHeader(
                      title: "Menu Baru",
                      showArrows: false,
                      onSeeAllTap: widget.onGoToProduct,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 106,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: provider.newMenus.length,
                        itemBuilder: (context, index) {
                          return StaggeredFadeAnimation(
                            index: index,
                            child: NewMenuCard(
                                product: provider.newMenus[index]),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 48),

                    // Footer
                    HomeFooter(),
                  ],
                ],
              ),
            ),
    );
  }
}
```

```dart
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

  // Getters untuk diakses oleh UI
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get sortOption => _sortOption;

  /// Memfilter produk unggulan (Bestseller)
  List<ProductModel> get bestsellers =>
      _products.where((p) => p.isBestseller == true).toList();

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
      final response = await http.get(uri).timeout(Duration(seconds: 10));

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
        // Tampilkan bestseller di atas
        _products.sort((a, b) =>
            (b.isBestseller ? 1 : 0).compareTo(a.isBestseller ? 1 : 0));
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
}
```
