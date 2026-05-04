import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../presentation/pages/profile/order_detail_page.dart';
import '../models/notification_model.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notif;

  const NotificationDetailScreen({super.key, required this.notif});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;

  bool _isLoadingOrder = false;
  Map<String, dynamic>? _associatedOrder;

  // Mengambil data pesanan spesifik untuk disandingkan dengan notifikasi
  Future<void> _fetchAssociatedOrder(String? orderRef, int? orderId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse(ApiService.userOrders),
        headers: {"Authorization": "Bearer ${auth.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> parsedOrders = [];
        if (data is List) {
          parsedOrders = data;
        } else if (data is Map && data.containsKey('data')) {
          parsedOrders = data['data'];
        }
        final order = parsedOrders.firstWhere(
          (o) {
            if (orderRef != null && o['order_ref'] == orderRef) return true;
            if (orderId != null && o['id'] == orderId) return true;
            return false;
          },
          orElse: () => null,
        );
        if (order != null && mounted) {
          setState(() {
            _associatedOrder = order;
          });
        }
      }
    } catch (e) {
      debugPrint("Error auto-fetching associated order: $e");
    }
  }

  // Mengambil riwayat pesanan dari backend API dan mencocokkan dengan rujukan/ID pesanan
  Future<void> _viewOrderDetails(String? orderRef, int? orderId) async {
    setState(() => _isLoadingOrder = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse(ApiService.userOrders),
        headers: {"Authorization": "Bearer ${auth.token}"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> parsedOrders = [];
        if (data is List) {
          parsedOrders = data;
        } else if (data is Map && data.containsKey('data')) {
          parsedOrders = data['data'];
        }

        final order = parsedOrders.firstWhere(
          (o) {
            if (orderRef != null && o['order_ref'] == orderRef) return true;
            if (orderId != null && o['id'] == orderId) return true;
            return false;
          },
          orElse: () => null,
        );

        if (order != null) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(order: order),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pesanan tidak ditemukan di riwayat Anda")),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat pesanan (${response.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isLoadingOrder = false);
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Animasi ikon: scale dari 0.5 → 1.0 dengan bounce
    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Animasi ikon: fade in cepat
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Animasi konten teks: slide dari bawah + fade in
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );

    // Jalankan animasi segera saat layar terbuka
    _iconController.forward();

    // Auto-fetch data pesanan terkait jika pesan notifikasi mengandung rujukan/ID pesanan
    final refMatch = RegExp(r'(515-\d+)').firstMatch(widget.notif.message)?.group(1);
    final idMatch = RegExp(r'#(\d+)').firstMatch(widget.notif.message)?.group(1);
    final int? orderId = idMatch != null ? int.tryParse(idMatch) : null;
    if (refMatch != null || orderId != null) {
      _fetchAssociatedOrder(refMatch, orderId);
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  String _formatFullDate(DateTime dt) {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const hari = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    final namaHari = hari[dt.weekday - 1];
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '$namaHari, ${dt.day} ${bulan[dt.month]} ${dt.year} • $jam:$menit';
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notif;

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        backgroundColor: context.colors.bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.colors.textDark),
        title: Text(
          'Detail Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.colors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Ikon Besar dengan Animasi ──────────────────────────────────
            AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _iconFade,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: child,
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lingkaran glow
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          context.colors.primaryOrange.withValues(alpha: 0.2),
                          context.colors.primaryOrange.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Lingkaran ikon utama
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          context.colors.primaryOrange,
                          context.colors.primaryOrange.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primaryOrange
                              .withValues(alpha: 0.4),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bakery_dining_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Konten Teks dengan Animasi Slide ──────────────────────────
            AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? context.colors.surface
                          : context.colors.primaryOrange
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: notif.isRead
                            ? Colors.grey.withValues(alpha: 0.2)
                            : context.colors.primaryOrange
                                .withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          notif.isRead
                              ? Icons.check_circle_rounded
                              : Icons.fiber_new_rounded,
                          size: 14,
                          color: notif.isRead
                              ? Colors.grey
                              : context.colors.primaryOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          notif.isRead ? 'Sudah Dibaca' : 'Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: notif.isRead
                                ? context.colors.textGrey
                                : context.colors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Judul
                  Text(
                    notif.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textDark,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Waktu lengkap
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: context.colors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        notif.timeAgo(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textHint,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Garis pembatas elegan
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: context.colors.textHint.withValues(alpha: 0.2),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.message_rounded,
                          size: 16,
                          color: context.colors.textHint.withValues(alpha: 0.5),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: context.colors.textHint.withValues(alpha: 0.2),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Pesan lengkap
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      notif.message,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: context.colors.textGrey,
                        height: 1.75,
                      ),
                    ),
                  ),

                  if (_associatedOrder != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tag_rounded, size: 16, color: context.colors.primaryOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Ref Pesanan: ${_associatedOrder!['order_ref'] ?? '#ROTI515-${_associatedOrder!['id']}'}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 16, color: const Color(0xFFD47311)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Jam Pengambilan: ${_associatedOrder!['pickup_time'] ?? 'Belum ditentukan'}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD47311),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Tanggal lengkap (formatted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: context.colors.textHint.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatFullDate(notif.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color:
                              context.colors.textHint.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Mem-parse order rujukan atau ID dari pesan notifikasi jika ada
                  (() {
                    final refMatch = RegExp(r'(515-\d+)').firstMatch(notif.message)?.group(1);
                    final idMatch = RegExp(r'#(\d+)').firstMatch(notif.message)?.group(1);
                    final int? orderId = idMatch != null ? int.tryParse(idMatch) : null;

                    return Column(
                      children: [
                        if (refMatch != null || orderId != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingOrder ? null : () => _viewOrderDetails(refMatch, orderId),
                              icon: _isLoadingOrder
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.receipt_long_rounded, size: 18),
                              label: Text(
                                'Lihat Detail Pesanan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.primaryOrange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Tombol Tutup / Kembali
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 16,
                              color: (refMatch != null || orderId != null) ? context.colors.primaryOrange : Colors.white,
                            ),
                            label: Text(
                              'Kembali',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (refMatch != null || orderId != null)
                                  ? context.colors.primaryOrange.withValues(alpha: 0.1)
                                  : context.colors.primaryOrange,
                              foregroundColor: (refMatch != null || orderId != null)
                                  ? context.colors.primaryOrange
                                  : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  })(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
