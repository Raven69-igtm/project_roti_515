import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State untuk menyimpan preferensi notifikasi secara lokal di UI
  bool _orderNotification = true;

  @override
  Widget build(BuildContext context) {
    // Mengambil status tema aktif (Mode Gelap/Terang) dari ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Notifikasi"),
            _buildSettingCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.receipt_long_outlined,
                  title: "Notifikasi Pesanan",
                  subtitle: "Pembaruan status pesanan Anda",
                  value: _orderNotification,
                  onChanged: (val) => setState(() => _orderNotification = val),
                ),
              ],
            ),
            
            SizedBox(height: 28),
            _buildSectionLabel("Keamanan & Privasi"),
            _buildSettingCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Kebijakan Privasi",
                  onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.article_outlined,
                  title: "Syarat & Ketentuan",
                  onTap: () => Navigator.pushNamed(context, AppRoutes.termsConditions),
                ),
              ],
            ),

            SizedBox(height: 28),
            _buildSectionLabel("Tampilan"),
            _buildSettingCard(
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: "Mode Gelap",
                  subtitle: "Ubah tampilan aplikasi menjadi gelap",
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                ),
              ],
            ),
            
            SizedBox(height: 40),
            Center(
              child: Text(
                "Roti 515 App v1.0.0",
                style: GoogleFonts.plusJakartaSans(
                  color: context.colors.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Membangun AppBar atas dengan tombol kembali ke halaman profil
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.bgColor.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 60,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.colors.textDark,
              size: 18,
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Text(
        'Pengaturan Utama',
        style: GoogleFonts.plusJakartaSans(
          color: context.colors.textDark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(color: Color(0xFFF3F4F6), height: 1),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.colors.textHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: context.colors.textDark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.divider,
      indent: 60, // Sesuaikan agar garis sejajar dengan teks
      endIndent: 20,
    );
  }

  // Widget pembangun item menu dengan tombol Switch (misal untuk toggle Notifikasi & Mode Gelap)
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primaryOrange, size: 22),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.colors.white,
            activeTrackColor: context.colors.primaryOrange,
            inactiveThumbColor: context.colors.white,
            inactiveTrackColor: context.colors.textHint.withValues(alpha: 0.3),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  // Widget pembangun item menu navigasi (membuka halaman Kebijakan Privasi / Syarat Ketentuan)
  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9), // Slate 100
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Color(0xFF64748B), size: 22),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textHint,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
