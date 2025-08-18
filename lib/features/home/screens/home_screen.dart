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
    Future.microtask(() {
      productProvider.fetchProducts();
      productProvider.startPolling();
    });
  }

  @override
  void dispose() {
    // Hentikan polling saat HomeScreen dihancurkan
    Provider.of<ProductProvider>(context, listen: false).stopPolling();
    _bestsellerScrollController.dispose();
    super.dispose();
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
                      height: 285,
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
