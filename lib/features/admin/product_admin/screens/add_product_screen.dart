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

  // ✅ Variabel untuk menyimpan gambar yang dipilih
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

  // ✅ Fungsi untuk membuka Galeri
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompres sedikit agar tidak terlalu besar
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

      // Kirim data produk dengan file gambar sebagai multipart
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
          imageFile: _imageFile, // null = tidak ganti gambar
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
                    _buildUploadArea(), // ✅ Sekarang memanggil pemilih gambar
                    SizedBox(height: 32),

                    _buildInputLabel("Nama Produk"),
                    _buildPillTextField(
                      controller: _nameController,
                      hint: "Contoh: Roti Keju",
                    ),
                    SizedBox(height: 24),

                    _buildInputLabel("Category"),
                    _buildPillDropdown(), // ✅ Kategori
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

  // =========================================================================
  // UI COMPONENTS
  // =========================================================================

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

  // ✅ UPDATE: Widget Upload Area sekarang menampilkan preview gambar
  Widget _buildUploadArea() {
    return InkWell(
      onTap: _pickImage, // Panggil fungsi Galeri
      borderRadius: BorderRadius.circular(48),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: _imageFile == null ? 52 : 0,
        ), // Hilangkan padding jika ada gambar
        decoration: BoxDecoration(
          color: context.colors.primaryOrange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(48),
          border: Border.all(
            color: context.colors.primaryOrange.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        clipBehavior: Clip
            .hardEdge, // Agar gambar yang di-load mengikuti bentuk radius 48
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
            // Tampilkan gambar berdasarkan platform (Web vs HP)
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

    // Safety check: jika _selectedCategory tidak ada di daftar, reset ke null
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
