Laporan Iterasi 2 - Fitur 4 (PB-09 & PB-10 - Notifikasi & UI/UX)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

d) Fitur 4: Notifikasi Sistem, Splash Screen & Desain Sistem Tema Kustom (PB-09 & PB-10 - Sistem mengirimkan notifikasi real-time dan implementasi splash screen / tema kustom)

1. Deskripsi Fitur
Fitur Notifikasi Sistem memberi tahu pelanggan tentang promosi toko serta status transaksi secara real-time. Pelanggan dapat memantau pesan masuk, menandai pesan sebagai terbaca, menghapus pesan satu per satu, maupun menghapus seluruh histori notifikasi. Selain itu, fitur UI/UX & Native menyajikan Splash Screen interaktif yang muncul sesaat ketika aplikasi dibuka (disertai efek kilauan cahaya pada logo) serta integrasi tema warna gelap/terang secara dinamis (Dark & Light Mode).

2. Implementasi Teknis & Alur Kerja
* REST API Sinkronisasi Notifikasi: Menghubungkan client dengan server melalui endpoint /api/notifications menggunakan request GET untuk memuat daftar notifikasi dan PUT untuk menandai notifikasi telah terbaca (markAsRead).
* Optimistic UI Updates: Mengurangi delay respon visual dengan menghapus data notifikasi secara langsung dari list lokal sesaat setelah aksi usap layar (dismissible swipe), lalu menyinkronkan penghapusan tersebut ke server di latar belakang.
* Efek Shine Shader Mask (Splash Screen): Menggunakan ShaderMask dan LinearGradient yang bergeser mengikuti sumbu diagonal berkat controller animasi _shineController untuk memproyeksikan kilatan cahaya halus di atas aset gambar logo.

3. Kode Sumber Lengkap (Full Source Code)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/staggered_fade_animation.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_detail_screen.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    Future.microtask(() {
      notificationProvider.fetchNotifications(authProvider.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: context.colors.bgColor, 
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: context.colors.bgColor,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            iconTheme: IconThemeData(color: context.colors.textDark),
            title: Text(
              "Notifikasi",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.textDark,
                letterSpacing: 0,
              ),
            ),
            actions: [
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.notifications.isEmpty) return SizedBox();
                  return Padding(
                    padding: EdgeInsets.only(right: 8.0, top: 8.0),
                    child: IconButton(
                      onPressed: () => _confirmDeleteAll(
                          context, provider, authProvider.token),
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                      tooltip: "Hapus Semua",
                    ),
                  );
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.notifications.isEmpty) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: context.colors.primaryOrange),
                    ),
                  );
                }

                if (provider.error.isNotEmpty && provider.notifications.isEmpty) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.wifi_off_rounded,
                                size: 50, color: Colors.redAccent),
                          ),
                          SizedBox(height: 20),
                          Text("Gagal Memuat Data",
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textDark)),
                          SizedBox(height: 8),
                          Text(provider.error,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, color: context.colors.textGrey)),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () =>
                                provider.fetchNotifications(authProvider.token),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primaryOrange,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99)),
                            ),
                            child: Text(
                              "Coba Lagi",
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.notifications.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      context.colors.primaryOrange
                                          .withValues(alpha: 0.15),
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x0C000000),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  size: 40,
                                  color: context.colors.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),
                          Text(
                            "Belum ada Notifikasi",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Kami akan memberi tahu saat ada promo\natau pembaruan pesanan Anda.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: context.colors.textGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: List.generate(provider.notifications.length,
                        (index) {
                      final notif = provider.notifications[index];
                      return Column(
                        children: [
                          StaggeredFadeAnimation(
                            index: index,
                            child: _buildNotificationCard(
                                notif, provider, authProvider.token),
                          ),
                          SizedBox(height: 16),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 80 + MediaQuery.of(context).padding.bottom,
            ),
          ),
        ],
      ),
    );
  }
}
```

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _error = '';

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(String? token) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    if (token == null || token.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return; 
    }

    try {
      final response = await http.get(
        Uri.parse(ApiService.notifications),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((n) => NotificationModel.fromJson(n)).toList();
      } else {
        _error = 'Gagal memuat notifikasi (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan jaringan.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id, String? token) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      final oldNotif = _notifications[index];
      _notifications[index] = NotificationModel(
        id: oldNotif.id,
        userId: oldNotif.userId,
        title: oldNotif.title,
        message: oldNotif.message,
        isRead: true,
        createdAt: oldNotif.createdAt,
      );
      notifyListeners();

      try {
        if (token != null) {
          await http.put(
            Uri.parse('${ApiService.notifications}/$id/read'),
            headers: {'Authorization': 'Bearer $token'},
          );
        }
      } catch (e) {}
    }
  }

  Future<void> deleteNotification(int id, String? token) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final removed = _notifications[index];
    _notifications.removeAt(index);
    notifyListeners();

    try {
      if (token != null && token.isNotEmpty) {
        final response = await http.delete(
          Uri.parse(ApiService.notificationById(id)),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode != 200 && response.statusCode != 204) {
          _notifications.insert(index, removed);
          notifyListeners();
        }
      }
    } catch (e) {
      _notifications.insert(index, removed);
      notifyListeners();
    }
  }

  Future<bool> deleteAllNotifications(String? token) async {
    if (token == null || token.isEmpty) return false;

    final oldNotifications = List<NotificationModel>.from(_notifications);
    
    _notifications.clear();
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse(ApiService.deleteAllNotifications),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _notifications = oldNotifications;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _notifications = oldNotifications;
      notifyListeners();
      return false;
    }
  }
}
```

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:roti_515/core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shineController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Interval(0.0, 0.8, curve: Curves.easeOutExpo),
      ),
    );

    _shineController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _shineAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );

    _entranceController.forward().then((_) {
      _shineController.forward();
    });

    Timer(Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.mainNav);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              context.colors.bgColor,
              context.colors.surface.withValues(alpha: 0.5),
            ],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entranceController, _shineController]),
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [
                          _shineAnimation.value - 0.5,
                          _shineAnimation.value,
                          _shineAnimation.value + 0.5,
                        ],
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.srcATop,
                    child: child,
                  ),
                ),
              );
            },
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark 
                ? 'assets/images/brand_logo_dark.png' 
                : 'assets/images/brand_logo.png',
              width: Theme.of(context).brightness == Brightness.dark ? 160 : 320, 
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
```
