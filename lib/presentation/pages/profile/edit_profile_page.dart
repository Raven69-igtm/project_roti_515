import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

// Project Imports
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/premium_snackbar.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  late String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    _addressController = TextEditingController(text: widget.userData['address'] ?? '');
    _currentPhotoUrl = widget.userData['photo_url'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIC: UPLOAD FOTO ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      var request = http.MultipartRequest('POST', Uri.parse(ApiService.uploadPhoto));
      request.headers['Authorization'] = 'Bearer $token';
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: image.name,
        contentType: MediaType('image', 'jpeg'),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentPhotoUrl = data['photo_url'];
            _isLoading = false;
          });
          PremiumSnackbar.showSuccess(context, "Foto profil berhasil diperbarui!");
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          PremiumSnackbar.showError(context, "Gagal mengunggah foto");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PremiumSnackbar.showError(context, "Error: $e");
      }
    }
  }

  // --- LOGIC: UPDATE PROFILE ---
  Future<void> _updateProfile() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isNotEmpty) {
      if (newPassword.length < 6) {
        PremiumSnackbar.showError(context, "Password baru minimal 6 karakter");
        return;
      }
      if (newPassword != confirmPassword) {
        PremiumSnackbar.showError(context, "Konfirmasi password tidak cocok");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final Map<String, dynamic> body = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
      };
      if (newPassword.isNotEmpty) {
        body["password"] = newPassword;
      }

      final response = await http.put(
        Uri.parse(ApiService.profile),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // Update local persistence just in case API doesn't hold it properly
          Provider.of<AuthProvider>(context, listen: false).updateProfileData(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
          );
          PremiumSnackbar.showSuccess(context, "Profil berhasil diperbarui!");
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          PremiumSnackbar.showError(context, "Gagal: ${response.body}");
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, "Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = "U";
    if (_nameController.text.isNotEmpty) {
      initials = _nameController.text[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        title: Text(
          "Pengaturan Akun",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: context.colors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // AVATAR SECTION
            Center(
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primaryOrange.withOpacity(0.15),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      padding: EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.surface,
                          image: (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(ApiService.getDisplayImage(_currentPhotoUrl)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                            ? Text(
                                initials,
                                style: GoogleFonts.pragatiNarrow(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textHint,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [context.colors.primaryOrange, Color(0xFFB85C00)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.surface, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primaryOrange.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Text(
                "Ganti Foto Profil",
                style: GoogleFonts.plusJakartaSans(
                  color: context.colors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            SizedBox(height: 40),

            // KARTU INFORMASI PROFIL
            _sectionTitle("Informasi Pribadi"),
            SizedBox(height: 16),
            _buildCard([
              _buildInputGroup("Nama Lengkap", _nameController, Icons.person_outline_rounded),
              _buildDivider(),
              _buildInputGroup("No. Telepon", _phoneController, Icons.phone_iphone_rounded, keyboardType: TextInputType.phone),
              _buildDivider(),
              _buildInputGroup("Alamat Domisili", _addressController, Icons.location_on_outlined),
            ]),

            SizedBox(height: 32),

            // KARTU KEAMANAN
            _sectionTitle("Keamanan Akun"),
            SizedBox(height: 16),
            _buildCard([
              _buildPasswordField(
                "Password Baru", 
                _newPasswordController, 
                _obscureNew, 
                () => setState(() => _obscureNew = !_obscureNew)
              ),
              _buildDivider(),
              _buildPasswordField(
                "Konfirmasi Password", 
                _confirmPasswordController, 
                _obscureConfirm, 
                () => setState(() => _obscureConfirm = !_obscureConfirm)
              ),
            ]),
            Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "* Biarkan kosong jika tidak ingin ganti password",
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: context.colors.textGrey, fontStyle: FontStyle.italic),
                ),
              ),
            ),

            SizedBox(height: 48),

            // TOMBOL SIMPAN
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [context.colors.primaryOrange, Color(0xFFB85C00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.primaryOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                    spreadRadius: -2,
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        "Simpan Perubahan",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.colors.textBrown,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: Offset(0, 12),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Divider(color: context.colors.divider.withOpacity(0.5), thickness: 1),
  );

  Widget _buildInputGroup(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: context.colors.primaryOrange.withOpacity(0.7)),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textGrey),
            ),
          ],
        ),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isReadOnly ? context.colors.textGrey : context.colors.textDark,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 26),
            hintText: "Masukkan $label",
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: context.colors.textHint, fontWeight: FontWeight.normal),
          ),
        )
      ],
    );
  }

  Widget _buildPasswordField(String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_person_outlined, size: 18, color: context.colors.primaryOrange.withOpacity(0.7)),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: context.colors.textGrey),
            ),
          ],
        ),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15, color: context.colors.textDark),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 26),
            hintText: "••••••••",
            hintStyle: TextStyle(color: context.colors.textHint.withOpacity(0.5)),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: context.colors.textHint,
              ),
              onPressed: onToggle,
            ),
          ),
        )
      ],
    );
  }
}
