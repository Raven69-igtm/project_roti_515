import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';
import '../models/order_model.dart';

/// Status loading untuk UI
enum OrderLoadState { idle, loading, success, error }

/// Provider yang mengambil data pesanan dari API dan mendukung polling otomatis
/// sehingga saat pelanggan checkout, pesanan baru otomatis muncul di admin.
/// Token autentikasi di-pass dari Screen agar bisa menggunakan AuthProvider.
class OrderAdminProvider extends ChangeNotifier {
  // --- STATE ---
  List<OrderModel> _allOrders = [];
  OrderLoadState _loadState = OrderLoadState.idle;
  String _errorMessage = '';

  // Tab aktif: 0=Tertunda, 1=Pengolahan, 2=Selesai
  int _activeTab = 0;

  // Timer untuk polling berkala (refresh tiap 10 detik)
  Timer? _pollingTimer;

  // Token autentikasi (di-set dari screen saat polling dimulai)
  String? _authToken;

  // --- GETTERS ---
  List<OrderModel> get allOrders => _allOrders;
  OrderLoadState get loadState => _loadState;
  String get errorMessage => _errorMessage;
  int get activeTab => _activeTab;

  /// Filter list sesuai tab aktif
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

  /// Hitung jumlah per status untuk badge angka
  int get pendingCount => _allOrders.where((o) => o.isPending).length;
  int get processingCount => _allOrders.where((o) => o.isProcessing).length;
  int get completedCount => _allOrders.where((o) => o.isCompleted).length;
  int get cancelledCount => _allOrders.where((o) => o.isCancelled).length;

  // --- HEADER BUILD ---
  Map<String, String> get _authHeaders => {
    "Content-Type": "application/json",
    if (_authToken != null && _authToken!.isNotEmpty)
      "Authorization": "Bearer $_authToken",
  };

  // --- AKSI ---

  /// Set tab aktif, lalu refresh tampilan
  void setTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  /// Mulai polling otomatis saat halaman dibuka.
  /// [token] adalah JWT Token dari AuthProvider.
  void startPolling(String? token) {
    _authToken = token;
    fetchOrders(); // Ambil data pertama kali langsung
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchOrders(silent: true); // Refresh diam-diam tanpa tampilkan loading
    });
  }

  /// Hentikan polling saat halaman ditutup
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Ambil daftar semua order dari API (memerlukan token admin)
  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) {
      _loadState = OrderLoadState.loading;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse(ApiService.adminOrders),  // ✅ /api/admin/orders bukan /api/orders
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
        // Selalu tampilkan error 401 (auth gagal) — hentikan polling agar tidak spam
        _errorMessage = 'Sesi login habis.\nSilakan login ulang sebagai Admin.';
        _loadState = OrderLoadState.error;
        stopPolling(); // 🛑 Berhenti poll agar tidak terus request tanpa token
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

  /// Update status pesanan (Tertunda → Pengolahan, dsb.)
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

  /// Hapus pesanan secara permanen (admin only)
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

  /// Set jam pengambilan untuk pesanan (admin only)
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

  /// Update data order secara lokal tanpa fetch ulang dari server
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
        jamAmbil: pickupTime ?? old.jamAmbil, // preserve jika tidak diubah
        createdAt: old.createdAt,
        items: old.items,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
