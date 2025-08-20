import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../product/screens/product_screen.dart'; 
import '../../favorite/screens/favorite_screen.dart'; 
import '../../auth/screens/login_screen.dart'; 
import '../../profile/screens/profile_screen.dart'; 
import '../widgets/main_bottom_nav_bar.dart';
import 'package:roti_515/core/theme/app_theme.dart'; // Import widget komponen modular navigasi

/// Layar induk yang memuat kerangka navigasi utama aplikasi (Bottom Navigation).
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  // Menyimpan status index menu (tab) yang sedang aktif di-klik pengguna
  int _selectedIndex = 0;

  /// Memilih widget layar/halaman mana yang akan di-render berdasarkan index aktif.
  Widget _buildBody() {
    // Mengekstrak status autentikasi untuk membatasi akses pada tab Profil
    final isLoggedIn = Provider.of<AuthProvider>(context).isLoggedIn;

    switch (_selectedIndex) {
      case 0: 
        return HomeScreen(
          onGoToProduct: () => setState(() => _selectedIndex = 1),
        ); // Layar Beranda
      case 1: 
        return ProductScreen(); // Layar Katalog Produk
      case 2: 
        return FavoriteScreen(); // Layar Favorit
      case 3: 
        // Logika Middleware Proteksi: Redirect ke Login bila belum memiliki sesi/token, jika sudah masuk Profil.
        return isLoggedIn ? ProfilePage() : LoginScreen();
      default: 
        return HomeScreen(
          onGoToProduct: () => setState(() => _selectedIndex = 1),
        ); // Fallback keamanan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      
      // Isi layar secara otomatis berganti komponen sesuai hasil buildBody dengan efek memudar
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _buildBody(),
      ),
      
      // Memanggil komponen Bottom Navigation yang sudah diekstrak agar Main Screen lebih bersih
      bottomNavigationBar: MainBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          // Memicu trigger rebuild UI apabila tab lain ditekan
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
