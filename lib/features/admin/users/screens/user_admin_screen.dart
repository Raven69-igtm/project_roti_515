import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/user_model.dart';
import '../providers/user_admin_provider.dart';
import '../../profile/screens/admin_profile_screen.dart';
import '../../product_admin/providers/admin_product_provider.dart';
import '../../dashboard/screens/admin_notification_screen.dart';
import '../../orders/providers/order_admin_provider.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';

class UserAdminScreen extends StatefulWidget {
  const UserAdminScreen({super.key});

  @override
  State<UserAdminScreen> createState() => _UserAdminScreenState();
}

class _UserAdminScreenState extends State<UserAdminScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mengambil token autentikasi dan memicu pemanggilan API data pengguna di provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final token = context.read<AuthProvider>().token;
        context.read<UserAdminProvider>().init(token);
      }
    });

    // Mendengarkan perubahan ketikan input pencarian nama/email secara realtime
    _searchController.addListener(() {
      if (mounted) {
        context.read<UserAdminProvider>().setSearchQuery(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    // Menghapus search controller untuk menghindari kebocoran memori
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserAdminProvider>();

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header "Manajemen Pengguna"
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Manajemen Pengguna',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                Text(
                  '${provider.totalUsers} Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textGrey,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.surface, borderRadius: BorderRadius.circular(48),
                border: Border.all(color: context.colors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Icon(Icons.search_rounded, color: context.colors.textHint, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: context.colors.textDark,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Cari berdasarkan nama atau email',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: context.colors.textHint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Tabs
          _UserTabBar(),

          // Konten List Pengguna
          Expanded(child: _UserListContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.bgColor,
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
        // Lonceng Notifikasi Admin
        Center(
          child: Consumer2<AdminProductProvider, OrderAdminProvider>(
            builder: (context, prodProvider, orderProvider, _) {
              final lowStockCount = prodProvider.allProducts.where((p) {
                final int stock = p['stock'] ?? 0;
                return stock <= 15;
              }).length;
              final pendingCount = orderProvider.pendingCount;
              final alertCount = lowStockCount + pendingCount;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminNotificationScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: alertCount > 0 ? context.colors.primaryOrange : context.colors.textDark,
                        size: 20,
                      ),
                      if (alertCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              "$alertCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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
        ),
      ],
    );
  }
}

// ============================================================
// TAB BAR: Semua | Admin | Pelanggan
// ============================================================
// Widget Tab Bar untuk memfilter tipe pengguna (Semua, Admin, Pelanggan)
class _UserTabBar extends StatelessWidget {
  const _UserTabBar();

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan state filter tab aktif di provider
    final provider = context.watch<UserAdminProvider>();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgColor,
        border: Border(
          bottom: BorderSide(
            color: context.colors.divider,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTabItem(context, 0, 'Semua', provider.activeTab),
            SizedBox(width: 24),
            _buildTabItem(context, 1, 'Admin', provider.activeTab),
            SizedBox(width: 24),
            _buildTabItem(context, 2, 'Pelanggan', provider.activeTab),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, String label, int activeTab) {
    final isActive = index == activeTab;
    final activeColor = context.colors.primaryOrange;
    final inactiveColor = context.colors.textGrey;

    return GestureDetector(
      onTap: () => context.read<UserAdminProvider>().setTab(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(top: 8, bottom: 12, left: 4, right: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? context.colors.textDark : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// KONTEN LIST PENGGUNA
// ============================================================
// Widget untuk merender list pengguna sesuai dengan state (loading, error, kosong, sukses)
class _UserListContent extends StatelessWidget {
  const _UserListContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserAdminProvider>();

    // Menampilkan indikator loading saat memanggil API get users
    if (provider.loadState == UserLoadState.loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.primaryOrange),
      );
    }

    if (provider.loadState == UserLoadState.error) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: context.colors.primaryOrange, size: 56),
              SizedBox(height: 16),
              Text(
                'Gagal Memuat Pengguna',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                provider.errorMessage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: context.colors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              GestureDetector(
                onTap: () => provider.fetchUsers(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.colors.primaryOrange,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final users = provider.filteredUsers;

    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(Icons.person_off_rounded, color: context.colors.primaryOrange.withValues(alpha: 0.4), size: 64),
              SizedBox(height: 16),
              Text(
                'Tidak ada data pengguna',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: context.colors.primaryOrange,
      onRefresh: () => provider.fetchUsers(),
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 100),
        itemCount: users.length,
        itemBuilder: (ctx, i) => _UserListItem(user: users[i]),
      ),
    );
  }
}

// ============================================================
// KOMPONEN ITEM PENGGUNA (Sesuai Desain HTML)
// ============================================================
// Widget kartu info detail user (Avatar, Nama, Email, Badge Role, Waktu Join)
class _UserListItem extends StatelessWidget {
  final UserModel user;
  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    // Menentukan role pengguna (Admin atau Pelanggan biasa) untuk styling badge & status
    final bool isAdmin = user.role.toLowerCase() == 'admin';
    // Gunakan indikator hijau jika admin (aktif) atau pengguna baru? Kita asumsikan hijau untuk pengguna baru/admin, abu-abu kalau lama
    // Atau kita bisa gunakan hijau untuk admin, abu abu untuk pelanggan. (Sesuai desain)
    final Color badgeColor = isAdmin ? Color(0xFF4F46E5) : Color(0xFFD47311);
    final Color badgeBgColor = isAdmin ? Color(0xFFE0E7FF) : Color(0xFFD47311).withValues(alpha: 0.10);
    final String badgeText = isAdmin ? 'Admin' : 'Pelanggan';
    
    // Status dot color bisa juga aktif/hijau jika admin
    final Color statusDotColor = isAdmin ? Color(0xFF22C55E) : (user.timeAgo == 'Sekarang' ? Color(0xFF22C55E) : Color(0xFFCBD5E1));

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: context.colors.divider),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Kiri: Avatar dengan Dot Indikator ──
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: context.colors.surface, width: 2),
                ),
                child: Center(
                  child: Text(
                    user.nama.isNotEmpty ? user.nama[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textGrey,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusDotColor,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: context.colors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),

          // ── Tengah: Detail Nama & Email ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama.isEmpty ? 'Pengguna Tidak Diketahui' : user.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textDark,
                    height: 20 / 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email.isEmpty ? '-' : user.email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textGrey,
                    height: 16 / 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),

          // ── Kanan: Badge Role & Waktu Gabung ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Center(
                  child: Text(
                    badgeText.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.50,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                isAdmin ? 'Aktif' : user.timeAgo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: context.colors.textHint,
                  height: 1.5,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
