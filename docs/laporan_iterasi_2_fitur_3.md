Laporan Iterasi 2 - Fitur 3 (PB-08 - Manajemen Pesanan Admin)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

c) Fitur 3: Manajemen Pesanan (PB-08 - Admin dapat memantau pesanan masuk, memperbarui status pesanan, dan mengelola histori pesanan)

1. Deskripsi Fitur
Fitur Manajemen Pesanan Admin bertindak sebagai konsol kontrol bagi pengelola toko untuk memantau semua transaksi masuk. Halaman ini membagi pesanan ke dalam 4 tab kategori utama berdasarkan status: Tertunda (Pending), Pengolahan (Processing), Selesai (Completed), dan Dibatalkan (Cancelled). Admin dapat menyetujui pesanan baru, memperbarui status pengerjaan roti, mengatur jam pengambilan pesanan, melihat rincian item belanjaan serta informasi pemesan, dan menghapus riwayat pesanan yang sudah tidak aktif.

2. Implementasi Teknis & Alur Kerja
* Polling Otomatis Sinkronisasi Cepat (Timer.periodic): Mengimplementasikan polling periodik setiap 10 detik di OrderAdminProvider untuk memperbarui daftar pesanan masuk dari API secara diam-diam (silent refresh) tanpa mengganggu visual interaksi admin.
* Efek Pulse Animasi Pesanan Baru: Menyertakan AnimationController kustom yang menghasilkan denyut visual elastis (pulse animation) pada pesanan berstatus Tertunda (Pending) sebagai isyarat visual penarik perhatian admin agar segera memproses pesanan tersebut.
* Pemberhentian Polling (Session Safety): Menghentikan polling secara otomatis jika terdeteksi respon HTTP status 401 (sesi admin kedaluwarsa) untuk menghemat sumber daya memori dan performa CPU.

3. Kode Sumber Lengkap (Full Source Code)

```dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';
import '../models/order_model.dart';
import '../providers/order_admin_provider.dart';
import '../../../../core/utils/premium_snackbar.dart';
import '../../../admin/dashboard/providers/admin_stats_provider.dart';
import '../../profile/screens/admin_profile_screen.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';

class OrderAdminScreen extends StatefulWidget {
  const OrderAdminScreen({super.key});

  @override
  State<OrderAdminScreen> createState() => _OrderAdminScreenState();
}

class _OrderAdminScreenState extends State<OrderAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final token = context.read<AuthProvider>().token;
        context.read<OrderAdminProvider>().startPolling(token);
      }
    });
  }

  @override
  void dispose() {
    context.read<OrderAdminProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _OrderTabBar(),
          Expanded(child: _OrderListContent()),
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

class _OrderTabBar extends StatelessWidget {
  const _OrderTabBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderAdminProvider>();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgColor,
        border: Border(
          bottom: BorderSide(
            color: context.colors.primaryOrange.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildTabItem(context, 0, 'Tertunda', provider.pendingCount, provider.activeTab),
            _buildTabItem(context, 1, 'Pengolahan', provider.processingCount, provider.activeTab),
            _buildTabItem(context, 2, 'Selesai', provider.completedCount, provider.activeTab),
            _buildTabItem(context, 3, 'Dibatalkan', provider.cancelledCount, provider.activeTab),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context,
    int index,
    String label,
    int count,
    int activeTab,
  ) {
    final isActive = index == activeTab;
    final activeColor = context.colors.primaryOrange;
    final inactiveColor = context.colors.textGrey;

    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<OrderAdminProvider>().setTab(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.only(top: 16, bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 3,
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
                  fontWeight: FontWeight.w700,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              if (count > 0) ...[
                SizedBox(height: 4),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.primaryOrange.withValues(alpha: isActive ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: context.colors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderListContent extends StatelessWidget {
  const _OrderListContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderAdminProvider>();

    if (provider.loadState == OrderLoadState.loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.primaryOrange),
      );
    }

    if (provider.loadState == OrderLoadState.error) {
      final bool isAuthError = provider.errorMessage.contains('login');

      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAuthError ? Icons.lock_outline_rounded : Icons.cloud_off_rounded,
                color: context.colors.primaryOrange,
                size: 56,
              ),
              SizedBox(height: 16),
              Text(
                isAuthError ? 'Sesi Admin Habis' : 'Gagal Memuat Pesanan',
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
              if (isAuthError)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.colors.primaryOrange,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'Login Ulang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => provider.fetchOrders(),
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

    final orders = provider.filteredOrders;

    if (orders.isEmpty) {
      return _buildEmptyState(context, provider.activeTab);
    }

    return RefreshIndicator(
      color: context.colors.primaryOrange,
      onRefresh: () => provider.fetchOrders(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: orders.length,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (ctx, i) => _OrderCard(order: orders[i]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int tab) {
    final messages = [
      'Tidak ada pesanan tertunda',
      'Tidak ada pesanan dalam pengolahan',
      'Belum ada pesanan selesai',
      'Tidak ada pesanan yang dibatalkan',
    ];
    final icons = [
      Icons.hourglass_empty_rounded,
      Icons.pending_actions_rounded,
      Icons.check_circle_outline_rounded,
      Icons.cancel_outlined,
    ];

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[tab], color: context.colors.primaryOrange.withValues(alpha: 0.4), size: 64),
            SizedBox(height: 16),
            Text(
              messages[tab],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pesanan baru akan muncul di sini secara otomatis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: context.colors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';
import '../models/order_model.dart';

enum OrderLoadState { idle, loading, success, error }

class OrderAdminProvider extends ChangeNotifier {
  List<OrderModel> _allOrders = [];
  OrderLoadState _loadState = OrderLoadState.idle;
  String _errorMessage = '';

  int _activeTab = 0;

  Timer? _pollingTimer;

  String? _authToken;

  OrderLoadState get loadState => _loadState;
  String get errorMessage => _errorMessage;
  int get activeTab => _activeTab;

  List<OrderModel> get filteredOrders {
    switch (_activeTab) {
      case 0:
        return _allOrders.where((o) => o.isPending).toList();
      case 1:
        return _allOrders.where((o) => o.isProcessing).toList();
      case 2:
        return _allOrders.where((o) => o.isCompleted).toList();
      case 3:
        return _allOrders.where((o) => o.isCancelled).toList();
      default:
        return [];
    }
  }

  int get pendingCount => _allOrders.where((o) => o.isPending).length;
  int get processingCount => _allOrders.where((o) => o.isProcessing).length;
  int get completedCount => _allOrders.where((o) => o.isCompleted).length;
  int get cancelledCount => _allOrders.where((o) => o.isCancelled).length;

  Map<String, String> get _authHeaders => {
    "Content-Type": "application/json",
    if (_authToken != null && _authToken!.isNotEmpty)
      "Authorization": "Bearer $_authToken",
  };

  void setTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  void startPolling(String? token) {
    _authToken = token;
    fetchOrders(); 
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchOrders(silent: true); 
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) {
      _loadState = OrderLoadState.loading;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse(ApiService.adminOrders),  
        headers: _authHeaders,
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          rawList = decoded['data'] as List;
        } else {
          rawList = [];
        }

        _allOrders = rawList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();

        _allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _loadState = OrderLoadState.success;
        _errorMessage = '';
      } else if (response.statusCode == 401) {
        _errorMessage = 'Sesi login habis.\nSilakan login ulang sebagai Admin.';
        _loadState = OrderLoadState.error;
        stopPolling(); 
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      if (!silent) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _loadState = OrderLoadState.error;
      }
    }

    notifyListeners();
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(ApiService.adminOrderById(orderId)),
        headers: _authHeaders,
        body: jsonEncode({"status": newStatus}),
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        _updateLocalOrder(orderId, status: newStatus);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteOrder(int orderId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiService.adminOrderById(orderId)),
        headers: _authHeaders,
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 204) {
        _allOrders.removeWhere((o) => o.id == orderId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setPickupTime(int orderId, String pickupTime) async {
    try {
      final response = await http.put(
        Uri.parse(ApiService.adminOrderById(orderId)),
        headers: _authHeaders,
        body: jsonEncode({"pickup_time": pickupTime}),
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        _updateLocalOrder(orderId, pickupTime: pickupTime);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _updateLocalOrder(int orderId, {String? status, String? pickupTime}) {
    final index = _allOrders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final old = _allOrders[index];
      _allOrders[index] = OrderModel(
        id: old.id,
        orderId: old.orderId,
        guestName: old.guestName,
        guestPhone: old.guestPhone,
        guestAddress: old.guestAddress,
        total: old.total,
        status: status ?? old.status,
        jamAmbil: pickupTime ?? old.jamAmbil, 
        createdAt: old.createdAt,
        items: old.items,
      );
      notifyListeners();
    }
  }
}
```
