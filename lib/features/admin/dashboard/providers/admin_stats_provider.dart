import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';
import '../../orders/models/order_model.dart';

class AdminStatsProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {
    "total_sales": 0,
    "total_orders": 0,
    "total_users": 0,
    "sales_growth": "0%",
    "orders_growth": "0%",
    "users_growth": "0%",
    "daily_stats": <Map<String, dynamic>>[],
    "activities": <Map<String, dynamic>>[],
  };
  bool _isLoading = true;
  Timer? _pollingTimer;

  // Token disimpan agar refreshNow() bisa digunakan tanpa passing token
  String? _cachedToken;

  // State untuk rekap bulanan
  Map<String, dynamic> _monthlyStats = {};
  bool _isLoadingMonthly = false;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get monthlyStats => _monthlyStats;
  bool get isLoadingMonthly => _isLoadingMonthly;

  void startPolling(String? token) {
    _cachedToken = token;
    fetchStats(token);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      fetchStats(token, silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh statistik secara langsung (dipanggil setelah admin selesaikan order)
  Future<void> refreshNow([String? token]) async {
    if (token != null) {
      _cachedToken = token;
    }
    await fetchStats(_cachedToken, silent: true);
  }

  Future<void> fetchStats(String? token, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse(ApiService.adminStats),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ambil growth dari backend jika tersedia, fallback ke '+0%'
        final String salesGrowth = _parseGrowth(
          data['sales_growth'] ?? data['revenue_growth'] ?? data['income_growth'],
        );
        final String ordersGrowth = _parseGrowth(
          data['orders_growth'] ?? data['order_growth'] ?? data['total_orders_growth'],
        );
        final String usersGrowth = _parseGrowth(
          data['users_growth'] ?? data['user_growth'] ?? data['new_users_growth'],
        );

        // Coba semua kemungkinan nama field untuk revenue/penjualan
        final dynamic rawSales = data['revenue']
            ?? data['total_revenue']
            ?? data['total_sales']
            ?? data['sales']
            ?? data['income']
            ?? 0;

        // Coba semua kemungkinan nama field untuk total order
        final dynamic rawOrders = data['total_order']
            ?? data['total_orders']
            ?? data['orders_count']
            ?? data['order_count']
            ?? data['completed_orders']
            ?? 0;

        // Coba semua kemungkinan nama field untuk new users
        final dynamic rawUsers = data['new_users']
            ?? data['total_users']
            ?? data['user_count']
            ?? data['users_count']
            ?? 0;

        _stats = {
          "total_sales": rawSales,
          "total_orders": rawOrders,
          "total_users": rawUsers,
          "sales_growth": salesGrowth,
          "orders_growth": ordersGrowth,
          "users_growth": usersGrowth,
          "daily_stats": data['daily_stats'] ?? [],
          "activities": data['activities'] ?? [],
        };
      } else {
        debugPrint("Stats API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch rekap bulanan berdasarkan bulan dan tahun
  Future<void> fetchMonthlyStats(int month, int year, {String? category}) async {
    _isLoadingMonthly = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiService.adminOrders),
        headers: {
          "Content-Type": "application/json",
          if (_cachedToken != null) "Authorization": "Bearer $_cachedToken",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          rawList = decoded['data'] as List;
        }

        final List<OrderModel> allOrders = rawList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Tentukan jumlah hari dalam bulan
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final Map<String, Map<String, dynamic>> dailyMap = {};
        for (int day = 1; day <= daysInMonth; day++) {
          final dateStr = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
          dailyMap[dateStr] = {
            "date": dateStr,
            "revenue": 0.0,
            "orders": 0,
          };
        }

        double totalRevenue = 0.0;
        int totalOrdersCount = 0;

        for (var order in allOrders) {
          final dt = order.createdAt;
          if (dt.month != month || dt.year != year) continue;
          final status = order.status.toLowerCase();
          if (status != 'completed' && status != 'done' && status != 'completed_unconfirmed') continue;

          final dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
          
          double orderRevenue = 0.0;
          bool hasMatchingItem = false;

          if (category != null && category != 'Semua') {
            for (var item in order.items) {
              if (item.category.toLowerCase() == category.toLowerCase()) {
                orderRevenue += item.price * item.quantity;
                hasMatchingItem = true;
              }
            }
          } else {
            orderRevenue = order.total.toDouble();
            hasMatchingItem = true;
          }

          if (hasMatchingItem && orderRevenue > 0) {
            totalRevenue += orderRevenue;
            totalOrdersCount += 1;
            if (dailyMap.containsKey(dateStr)) {
              dailyMap[dateStr]!['revenue'] = (dailyMap[dateStr]!['revenue'] as double) + orderRevenue;
              dailyMap[dateStr]!['orders'] = (dailyMap[dateStr]!['orders'] as int) + 1;
            }
          }
        }

        final List<Map<String, dynamic>> dailyList = dailyMap.values.toList();
        dailyList.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

        // Rata-rata pesanan per hari
        final now = DateTime.now();
        int activeDays = daysInMonth;
        if (now.month == month && now.year == year) {
          activeDays = now.day;
        }
        final avgDailyOrders = activeDays > 0 ? (totalOrdersCount / activeDays).round() : 0;

        _monthlyStats = {
          "month": month,
          "year": year,
          "total_revenue": totalRevenue,
          "total_orders": totalOrdersCount,
          "avg_daily_orders": avgDailyOrders,
          "daily_stats": dailyList,
        };
      } else {
        _monthlyStats = {};
      }
    } catch (e) {
      debugPrint("Error fetching monthly stats: $e");
      _monthlyStats = {};
    } finally {
      _isLoadingMonthly = false;
      notifyListeners();
    }
  }

  /// Parsing nilai growth dari API — bisa berupa String atau angka
  String _parseGrowth(dynamic raw) {
    if (raw == null) return '+0%';
    if (raw is String) {
      // Pastikan diawali '+' jika positif
      if (raw.startsWith('+') || raw.startsWith('-')) return raw;
      return '+$raw';
    }
    if (raw is num) {
      final sign = raw >= 0 ? '+' : '';
      return '$sign${raw.toStringAsFixed(0)}%';
    }
    return '+0%';
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

