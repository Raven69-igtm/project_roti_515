Laporan Fitur 3 (PB-04 - Manajemen Produk)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

c) Fitur 3: Manajemen Produk (Fitur CRUD Produk Roti oleh Admin)

1. Deskripsi Fitur
Fitur Manajemen Produk dirancang khusus untuk peran Admin agar dapat melakukan operasi CRUD (Create, Read, Update, Delete) pada data produk roti. Admin dapat memantau seluruh katalog produk, menyaring produk berdasarkan tab tertentu (semua produk, stok habis, stok menipis), memperbarui jumlah stok dengan dialog cepat, mengunggah foto produk baru dari galeri HP, serta menyunting detail data (nama, harga, kategori, deskripsi) atau menghapus produk yang sudah tidak dijual lagi.

2. Implementasi Teknis & Alur Kerja
* Multipart HTTP Request: Proses penyimpanan produk baru maupun pembaruan data yang menyertakan file gambar dikirimkan ke backend Go menggunakan MultipartRequest dengan tipe konten image/jpeg.
* Image Picker: Menggunakan package image_picker untuk mempermudah pemilihan foto produk langsung dari galeri lokal HP pengguna.
* Manajemen Stok Interaktif: Admin dapat menambah stok produk secara cepat (Quick Restock) langsung dari list utama menggunakan dialog input tanpa harus masuk ke form penyuntingan penuh.

3. Kode Sumber Lengkap (Full Source Code)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_product_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/utils/premium_snackbar.dart';
import '../../../../core/widgets/universal_image.dart';
import 'add_product_screen.dart';
import '../../profile/screens/admin_profile_screen.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';

class ProductAdminScreen extends StatefulWidget {
  const ProductAdminScreen({super.key});

  @override
  State<ProductAdminScreen> createState() => _ProductAdminScreenState();
}

class _ProductAdminScreenState extends State<ProductAdminScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProductProvider>(context, listen: false).fetchProducts();
    });

    _searchController.addListener(() {
      Provider.of<AdminProductProvider>(context, listen: false)
          .setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProductProvider>(context);

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchBar(context),
          ),
          SizedBox(height: 16),
          _buildFilterTabs(context, provider),
          SizedBox(height: 16),
          Expanded(
            child: _buildBodyContent(context, provider),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 90), 
        child: FloatingActionButton(
          backgroundColor: context.colors.primaryOrange,
          elevation: 6,
          onPressed: () {
            Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddProductScreen()),
            );
          },
          child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, AdminProductProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: context.colors.primaryOrange));
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: context.colors.textHint),
            SizedBox(height: 16),
            Text(provider.errorMessage!, style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey), textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchProducts(),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.primaryOrange, shape: StadiumBorder()),
              child: Text("Coba Lagi", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    final products = provider.filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Text("Tidak ada produk ditemukan.", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey)),
      );
    }

    return RefreshIndicator(
      color: context.colors.primaryOrange,
      onRefresh: () => provider.fetchProducts(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 120),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          
          final String name = product["name"] ?? "Tanpa Nama";
          final String priceStr = (product["price"] ?? 0).toString();
          final int stock = product["stock"] ?? 0;
          
          final String imageUrl = (product["image_url"] != null && product["image_url"].toString().isNotEmpty)
              ? product["image_url"] 
              : "https://via.placeholder.com/150"; 
          
          final double rating = (product["rating"] as num?)?.toDouble() ?? 0.0;
          
          return _buildProductCard(context, 
            name: name,
            price: "Rp $priceStr",
            stock: stock,
            imageUrl: imageUrl,
            rating: rating,
            onQuickRestock: () => _showQuickRestockDialog(context, product),
            onEdit: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(initialProduct: product),
                ),
              );
            },
            onDelete: () => _confirmDelete(context, product),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.bgColor.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Image.asset(
              'assets/images/app_icon-removebg-preview.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("roti515", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textDark)),
              Text("Portal Admin", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.primaryOrange)),
            ],
          ),
        ],
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.colors.textDark,
            ),
            onPressed: () => theme.toggleTheme(!theme.isDarkMode),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => AdminProfileScreen()),
              );
            },
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final photoUrl = auth.photoUrl;
                final fullImageUrl = ApiService.getDisplayImage(photoUrl);

                Widget imageChild;
                if (fullImageUrl.isEmpty) {
                  imageChild = Icon(
                    Icons.account_circle_outlined,
                    color: context.colors.primaryOrange,
                    size: 22,
                  );
                } else if (fullImageUrl.startsWith('data:image')) {
                  try {
                    final base64Str = fullImageUrl.split(',').last;
                    final decodedBytes = base64Decode(base64Str);
                    imageChild = Image.memory(
                      decodedBytes,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle_outlined,
                        color: context.colors.primaryOrange,
                        size: 22,
                      ),
                    );
                  } catch (_) {
                    imageChild = Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    );
                  }
                } else {
                  imageChild = Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    ),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.primaryOrange,
                          ),
                        ),
                      );
                    },
                  );
                }

                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primaryOrange.withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageChild,
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: context.colors.textDark),
        decoration: InputDecoration(
          hintText: "Cari Produk",
          hintStyle: GoogleFonts.plusJakartaSans(color: context.colors.textHint, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: context.colors.primaryOrange, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, AdminProductProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.colors.primaryOrange.withValues(alpha: 0.1)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabItem(context, "Semua Produk", 0, provider),
          _buildTabItem(context, "Stok Habis", 1, provider),
          _buildTabItem(context, "Stok Menipis", 2, provider),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String title, int index, AdminProductProvider provider) {
    bool isActive = provider.selectedTab == index;
    return GestureDetector(
      onTap: () => provider.setTab(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? context.colors.primaryOrange : Colors.transparent, width: 3)),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.bold,
            color: isActive ? context.colors.primaryOrange : context.colors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, {
    required String name, required String price, required int stock, required String imageUrl, required double rating,
    required VoidCallback onEdit, required VoidCallback onDelete, VoidCallback? onQuickRestock,
  }) {
    Color stockBgColor = stock == 0 ? Color(0xFFFEE2E2) : stock <= 15 ? Color(0xFFFFEDD5) : Color(0xFFDCFCE7);
    Color stockTextColor = stock == 0 ? Color(0xFFB91C1C) : stock <= 15 ? Color(0xFFC2410C) : Color(0xFF15803D);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: UniversalImage(
              imageUrl: imageUrl, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 80, height: 80, color: context.colors.divider, 
                child: Icon(Icons.image_not_supported_rounded, color: context.colors.textGrey)
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text(price, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.primaryOrange)),
                SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Stok: ", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: context.colors.textGrey)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: stockBgColor, borderRadius: BorderRadius.circular(9999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (stock > 0 && stock <= 15)
                                Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.warning_amber_rounded, size: 12, color: stockTextColor),
                                ),
                              Text("$stock", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: stockTextColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textDark)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (stock <= 15 && onQuickRestock != null) ...[
                _buildActionButton(context, Icons.add_shopping_cart_rounded, context.colors.primaryOrange, onQuickRestock),
                SizedBox(width: 8),
              ],
              _buildActionButton(context, Icons.edit_rounded, Color(0xFF16A34A), onEdit),
              SizedBox(width: 8),
              _buildActionButton(context, Icons.delete_outline_rounded, Color(0xFFEF4444), onDelete),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text("Hapus Produk?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: context.colors.textDark)),
        content: Text("Apakah Anda yakin ingin menghapus ${product['name']}? Tindakan ini tidak dapat dibatalkan.", style: GoogleFonts.plusJakartaSans(color: context.colors.textDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<AdminProductProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final token = auth.token ?? '';
              
              bool success = await provider.deleteProduct(product['id'], token);
              if (mounted) {
                if (success) {
                  PremiumSnackbar.showSuccess(context, "Produk berhasil dihapus");
                } else {
                  PremiumSnackbar.showError(context, "Gagal menghapus produk: ${provider.errorMessage}");
                }
              }
            },
            child: Text("Hapus", style: GoogleFonts.plusJakartaSans(color: context.colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickRestockDialog(BuildContext context, Map<String, dynamic> product) {
    final TextEditingController stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text("Tambah Stok ${product['name']}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Masukkan jumlah stok yang ditambahkan:", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: context.colors.textDark)),
            SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(color: context.colors.textDark),
              decoration: InputDecoration(
                hintText: "Contoh: 10",
                hintStyle: GoogleFonts.plusJakartaSans(color: context.colors.textHint),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.primaryOrange)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final int addedStock = int.tryParse(stockController.text) ?? 0;
              if (addedStock <= 0) {
                PremiumSnackbar.showError(ctx, "Masukkan jumlah stok yang valid");
                return;
              }

              Navigator.pop(ctx);
              final provider = Provider.of<AdminProductProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final int newStock = (product['stock'] ?? 0) + addedStock;

              bool success = await provider.updateProduct(
                id: product['id'],
                name: product['name'],
                category: product['category'] ?? "Lainnya",
                price: product['price'],
                stock: newStock,
                token: auth.token ?? '',
              );

              if (context.mounted) {
                if (success) {
                  PremiumSnackbar.showSuccess(context, "Stok berhasil ditambahkan");
                } else {
                  PremiumSnackbar.showError(context, "Gagal menambah stok");
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.primaryOrange),
            child: Text("Simpan", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
```

```dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // ✅ Import image_picker

import '../providers/admin_product_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/utils/premium_snackbar.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProduct;
  const AddProductScreen({super.key, this.initialProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedCategory;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _nameController.text = widget.initialProduct!['name'] ?? '';
      _priceController.text = (widget.initialProduct!['price'] ?? 0).toString();
      _stockController.text = (widget.initialProduct!['stock'] ?? 0).toString();
      _descController.text = widget.initialProduct!['description'] ?? '';
      _selectedCategory = widget.initialProduct!['category'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar("Gagal mengambil gambar: $e");
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        _showSnackBar("Pilih kategori terlebih dahulu!");
        return;
      }
      if (_imageFile == null && widget.initialProduct == null) {
        _showSnackBar("Pilih gambar produk terlebih dahulu!");
        return;
      }

      final provider = Provider.of<AdminProductProvider>(
        context,
        listen: false,
      );
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token ?? '';

      final navigator = Navigator.of(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: context.colors.primaryOrange),
        ),
      );

      bool success;
      if (widget.initialProduct != null) {
        success = await provider.updateProduct(
          id: widget.initialProduct!['id'],
          name: _nameController.text,
          category: _selectedCategory!,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          description: _descController.text,
          token: token,
          imageFile: _imageFile, 
        );
      } else {
        success = await provider.addProduct(
          name: _nameController.text,
          category: _selectedCategory!,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          description: _descController.text,
          token: token,
          imageFile: _imageFile,
        );
      }

      if (!mounted) return;
      navigator.pop(); // Tutup loading

      if (success) {
        PremiumSnackbar.showSuccess(
          context,
          widget.initialProduct != null
              ? "Produk berhasil diperbarui"
              : "Produk berhasil ditambahkan",
        );
        navigator.pop();
      } else {
        PremiumSnackbar.showError(context, provider.errorMessage ?? "Gagal menyimpan produk");
      }
    }
  }

  void _showSnackBar(String message) {
    if (message.contains("berhasil")) {
      PremiumSnackbar.showSuccess(context, message.replaceAll("✅ ", ""));
    } else {
      PremiumSnackbar.showError(context, message.replaceAll("❌ ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel("Gambar Produk"),
                    _buildUploadArea(), 
                    SizedBox(height: 32),

                    _buildInputLabel("Nama Produk"),
                    _buildPillTextField(
                      controller: _nameController,
                      hint: "Contoh: Roti Keju",
                    ),
                    SizedBox(height: 24),

                    _buildInputLabel("Category"),
                    _buildPillDropdown(), 
                    SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel("Harga (Rp)"),
                              _buildPillTextField(
                                controller: _priceController,
                                hint: "0",
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel("Jumlah Stok"),
                              _buildPillTextField(
                                controller: _stockController,
                                hint: "0",
                                isNumber: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    _buildInputLabel("Deskripsi"),
                    _buildDescriptionField(controller: _descController),
                    SizedBox(height: 32),

                    _buildSaveButton(),
                    SizedBox(height: 16),
                    _buildBackButton(),
                    SizedBox(height: 128),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(72),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AppBar(
            backgroundColor: context.colors.bgColor.withValues(alpha: 0.8),
            elevation: 0,
            automaticallyImplyLeading: false,
            shape: Border(
              bottom: BorderSide(
                color: context.colors.primaryOrange.withValues(alpha: 0.1),
              ),
            ),
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.colors.primaryOrange,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.initialProduct != null
                          ? "Edit Produk"
                          : "Tambah Produk",
                      style: GoogleFonts.plusJakartaSans(
                        color: context.colors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Consumer<ThemeProvider>(
                  builder: (context, theme, _) => IconButton(
                    icon: Icon(
                      theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: context.colors.textDark,
                      size: 20,
                    ),
                    onPressed: () => theme.toggleTheme(!theme.isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: context.colors.textGrey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: context.colors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      onTap: _pickImage, 
      borderRadius: BorderRadius.circular(48),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: _imageFile == null ? 52 : 0,
        ), 
        decoration: BoxDecoration(
          color: context.colors.primaryOrange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(48),
          border: Border.all(
            color: context.colors.primaryOrange.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        clipBehavior: Clip.hardEdge, 
        child: _imageFile == null
            ? Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: context.colors.primaryOrange,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Unggah Gambar Produk",
                    style: GoogleFonts.plusJakartaSans(
                      color: context.colors.primaryOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Format yang didukung: JPG, PNG. Ukuran maksimum 2MB",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: context.colors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : kIsWeb
            ? Image.network(
                _imageFile!.path,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              )
            : Image.file(
                File(_imageFile!.path),
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: context.colors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: context.colors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: context.colors.textHint,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Wajib diisi" : null,
      ),
    );
  }

  Widget _buildPillDropdown() {
    final List<String> categories = [
      "Roti",
      "Biskuit",
      "Snack",
    ];

    if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: context.colors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text(
            "Pilih Kategori",
            style: GoogleFonts.plusJakartaSans(color: context.colors.textHint),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
          items: ["Roti", "Biskuit", "Snack"].map(
            (String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: context.colors.textDark,
                  ),
                ),
              );
            },
          ).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildDescriptionField({required TextEditingController controller}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        style: GoogleFonts.plusJakartaSans(fontSize: 16),
        decoration: InputDecoration(
          hintText: "Ceritakan kepada kami tentang produk ini...",
          hintStyle: GoogleFonts.plusJakartaSans(
            color: context.colors.textHint,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _submitData,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: context.colors.primaryOrange,
          borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: context.colors.primaryOrange.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Simpan Produk",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: Text(
            "Kembali",
            style: GoogleFonts.plusJakartaSans(
              color: context.colors.textGrey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_service.dart';

class AdminProductProvider extends ChangeNotifier {
  List<dynamic> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = "";
  int _selectedTab = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTab => _selectedTab;

  String get _baseUrl => ApiService.baseDomain;
  String get _apiUrl => ApiService.foods;

  List<dynamic> get filteredProducts {
    var list = _allProducts.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (_selectedTab == 1) {
      list = list.where((p) => (p['stock'] ?? 0) == 0).toList();
    } else if (_selectedTab == 2) {
      list = list.where((p) => (p['stock'] ?? 0) > 0 && (p['stock'] ?? 0) <= 15).toList();
      list.sort((a, b) => (a['stock'] ?? 0).compareTo(b['stock'] ?? 0));
    }
    
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
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
          String rawImage = p['image_url'] ?? '';
          
          if (rawImage.isNotEmpty && !rawImage.startsWith('http') && !rawImage.startsWith('data:image')) {
            if (!rawImage.startsWith('/static')) {
              if (!rawImage.startsWith('/')) rawImage = '/$rawImage';
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

  Future<bool> updateProduct({
    required int id,
    required String name,
    required String category,
    required int price,
    required int stock,
    required String token,
    String? description,
    XFile? imageFile,
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

  Future<bool> addProduct({
    required String name,
    required String category,
    required int price,
    required int stock,
    required String token,
    String? description,
    XFile? imageFile,
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
```
