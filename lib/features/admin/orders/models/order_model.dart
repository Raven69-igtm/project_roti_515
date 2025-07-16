import '../../../../core/network/api_service.dart';
import '../../../../core/models/order.dart';

// Model yang merepresentasikan satu item dalam pesanan, mewarisi ItemOrder (OOP)
class OrderItemModel extends ItemOrder {
  final String productName;
  final String imageUrl; // URL gambar produk dari server
  final String category;

  OrderItemModel({
    required super.orderId, // Diwarisi dari ItemOrder
    required super.produkId, // Diwarisi dari ItemOrder
    required this.productName,
    required this.imageUrl,
    required this.category,
    required super.qty, // Diwarisi dari ItemOrder
    required super.hargaSatuan, // Diwarisi dari ItemOrder
  });

  // Encapsulation: Getters
  int get productId => produkId;
  int get quantity => qty;
  double get price => hargaSatuan;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = (json['food'] ?? json['product']) as Map<String, dynamic>?;
    final rawName = product?['name'] as String? ?? '';
    final rawImage = product?['image_url'] as String? ?? '';
    final rawCategory = product?['category'] as String? ?? 'Lainnya';
    String fullImageUrl = '';
    if (rawImage.isNotEmpty) {
      if (rawImage.startsWith('http')) {
        fullImageUrl = rawImage;
      } else if (rawImage.startsWith('/static')) {
        fullImageUrl = '${ApiService.baseDomain}$rawImage';
      } else {
        final cleaned = rawImage.startsWith('/') ? rawImage : '/$rawImage';
        fullImageUrl = '${ApiService.baseDomain}/static$cleaned';
      }
    }

    return OrderItemModel(
      orderId: json['order_id'] ?? 0,
      produkId: json['product_id'] ?? 0,
      productName: rawName,
      imageUrl: fullImageUrl,
      category: rawCategory,
      qty: json['quantity'] ?? 0,
      hargaSatuan: (json['price'] ?? 0).toDouble(),
    );
  }
}

// Model utama untuk satu pesanan, mewarisi Order (OOP)
class OrderModel extends Order {
  final String orderId;
  final String guestName;
  final String guestPhone;
  final String guestAddress;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required super.id,
    required this.orderId,
    required this.guestName,
    required this.guestPhone,
    required this.guestAddress,
    required super.total,
    required super.status,
    super.jamAmbil = '', // Map ke jamAmbil di base class
    required this.createdAt,
    required this.items,
    String metodeBayar = 'Cash',
  }) : super(metodeBayar: metodeBayar);

  // Encapsulation: Getter untuk jamAmbil (pickupTime)
  String? get pickupTime => jamAmbil.isEmpty ? null : jamAmbil;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final List<OrderItemModel> parsedItems = [];
    if (json['items'] != null) {
      for (var item in (json['items'] as List)) {
        parsedItems.add(OrderItemModel.fromJson(item));
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'] ?? '').toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawId = json['id'] ?? 0;
    final formattedOrderId = (json['order_ref'] != null && json['order_ref'].toString().isNotEmpty)
        ? json['order_ref'].toString()
        : 'ROTI515-$rawId';

    // Backend kirim: pelanggan → user (nested) ATAU user langsung di top level
    final pelangganMap = json['pelanggan'] as Map<String, dynamic>?;
    final userMap = json['user'] as Map<String, dynamic>? ??
        (pelangganMap != null ? pelangganMap['user'] as Map<String, dynamic>? : null);

    final String parsedName = (userMap?['name'] ?? '').toString().isNotEmpty
        ? userMap!['name'].toString()
        : (json['guest_name']?.toString().isNotEmpty == true ? json['guest_name'] : 'Pelanggan Toko');

    final String parsedPhone = (pelangganMap?['phone'] ?? userMap?['phone'] ?? '').toString().isNotEmpty
        ? (pelangganMap?['phone'] ?? userMap?['phone']).toString()
        : (json['guest_phone']?.toString().isNotEmpty == true ? json['guest_phone'] : '-');

    final String parsedAddress = (userMap?['address'] ?? '').toString().isNotEmpty
        ? userMap!['address'].toString()
        : (json['guest_address']?.toString().isNotEmpty == true ? json['guest_address'] : 'Ambil Di Toko');

    return OrderModel(
      id: rawId,
      orderId: formattedOrderId,
      guestName: parsedName,
      guestPhone: parsedPhone,
      guestAddress: parsedAddress,
      total: (json['total'] ?? 0).toDouble(),
      status: (json['status'] ?? 'pending').toLowerCase(),
      jamAmbil: json['pickup_time'] ?? json['jam_ambil'] ?? '',
      createdAt: parsedDate,
      items: parsedItems,
      metodeBayar: json['metode_bayar'] ?? json['payment_method'] ?? 'Cash',
    );
  }

  // --- HELPER STATUS ---
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed' || status == 'done' || status == 'completed_unconfirmed';
  bool get isCancelled => status == 'cancelled';

  bool get hasPickupTime => jamAmbil.isNotEmpty;

  String get thumbnailImage =>
      items.isNotEmpty ? items.first.imageUrl : '';

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  String get formattedTotal {
    final totalInt = total.toInt();
    final s = totalInt.toString();
    final buf = StringBuffer('Rp ');
    final mod = s.length % 3;
    buf.write(s.substring(0, mod == 0 ? 3 : mod));
    for (int i = (mod == 0 ? 3 : mod); i < s.length; i += 3) {
      buf.write('.');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }
}
