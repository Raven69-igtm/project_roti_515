import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../profile/widgets/profile_header.dart';
import '../../../profile/widgets/profile_section_label.dart';
import '../../../profile/widgets/profile_menu_tile.dart';
import '../../../profile/widgets/profile_logout_button.dart';
import '../../../../presentation/pages/profile/edit_profile_page.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final String _apiUrl = ApiService.profile;

  @override
  void initState() {
    super.initState();
    // Memulai pemanggilan data profil admin dari server/API
    _fetchProfile();
  }

  // Fungsi mengambil profil admin dari backend menggunakan HTTP GET dan token otentikasi
  Future<void> _fetchProfile() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          final user = data['user'];
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          // Update global photoUrl di AuthProvider agar AppBar sinkron
          authProvider.updatePhotoUrl(user['photo_url']);

          // Inject data lokal (address/name/phone) karena API mungkin tidak menyimpannya
          if (authProvider.address != null && authProvider.address!.isNotEmpty) {
            user['address'] = authProvider.address;
          }
          if (authProvider.name != null && authProvider.name!.isNotEmpty) {
            user['name'] = authProvider.name;
          }
          if (authProvider.phone != null && authProvider.phone!.isNotEmpty) {
            user['phone'] = authProvider.phone;
          }

          setState(() {
            _userData = user;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching profile: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    // Menyiapkan nama lengkap dan email admin
    String fullName = _userData?['name'] ?? "Loading...";
    String email = _userData?['email'] ?? "memuat..";

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.primaryOrange, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profil Admin",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.textDark,
          ),
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
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 16),
                  ProfileHeader(
                    name: fullName, 
                    email: email,
                    photoUrl: _userData?['photo_url'],
                  ),
                  SizedBox(height: 24),
                  ProfileSectionLabel(label: "Aktivitas Akun"),
                  ProfileMenuTile(
                    icon: Icons.edit_rounded,
                    title: "Edit Profil",
                    subtitle: "Ubah nama, telepon & password",
                    onTap: () async {
                      if (_userData == null) return;
                      final updated = await Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(userData: _userData!),
                        ),
                      );
                      if (updated == true && mounted) {
                        _fetchProfile();
                      }
                    },
                  ),
                  SizedBox(height: 24),
                  ProfileSectionLabel(label: "Sistem"),
                  SizedBox(height: 16),
                  ProfileLogoutButton(),
                  SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
