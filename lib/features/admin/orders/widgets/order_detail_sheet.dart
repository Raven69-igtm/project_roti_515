import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import '../models/order_model.dart';
import '../providers/order_admin_provider.dart';

// Widget bottom sheet untuk menampilkan rincian pesanan dan pengelolaan jam pengambilan oleh Admin
class OrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  const OrderDetailSheet({super.key, required this.order});

  @override
  State<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<OrderDetailSheet> {
  bool _isSavingTime = false;

  // Fungsi untuk memunculkan pemilih Tanggal & Waktu (Date/Time Picker) untuk menetapkan jadwal ambil
  Future<void> _pickDateTime() async {
    // 1. Munculkan dialog kalender
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      helpText: 'Pilih Tanggal Pengambilan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.colors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: context.colors.textDark,
              surface: context.colors.surface,
            ),
            dialogBackgroundColor: context.colors.surface,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // 2. Munculkan dialog jam
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Pilih Jam Pengambilan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.colors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: context.colors.textDark,
              surface: context.colors.surface,
            ),
            dialogBackgroundColor: context.colors.surface,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    // 3. Format hasil pilihan (Contoh: "14 Apr 2026, 09:30")
    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final String formatted =
        '${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}, ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

    setState(() => _isSavingTime = true);
    final provider = context.read<OrderAdminProvider>();
    // Kirim data jadwal ambil baru ke server backend
    final success = await provider.setPickupTime(widget.order.id, formatted);
    if (mounted) {
      setState(() => _isSavingTime = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(
            success
                ? '✅ Jadwal pengambilan ditetapkan: $formatted'
                : '❌ Gagal menyimpan jadwal. Coba lagi.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: success ? context.colors.success : context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan spesifik pada pesanan ini agar tampilan langsung ter-refresh
    final latestOrder = context
        .watch<OrderAdminProvider>()
        .filteredOrders
        .firstWhere((o) => o.id == widget.order.id, orElse: () => widget.order);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.colors.bgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Handle bar kecil di atas sheet
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.divider,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),

                // Judul Sheet
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${latestOrder.orderId}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textDark,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.colors.divider,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, size: 18, color: context.colors.textGrey),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: context.colors.divider),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.all(20),
                    children: [
                      // INFO PELANGGAN
                      _buildSection(context, 'Informasi Pelanggan', [
                        _buildInfoRow(context, Icons.person_rounded, 'Nama', latestOrder.guestName),
                        _buildInfoRow(context, Icons.phone_rounded, 'Telepon', latestOrder.guestPhone),
                        _buildInfoRow(context, Icons.location_on_rounded, 'Alamat/Metode', latestOrder.guestAddress),
                      ]),

                      SizedBox(height: 16),

                      // JAM PENGAMBILAN (Memicu picker jadwal ambil)
                      _buildPickupTimeSection(context, latestOrder),

                      SizedBox(height: 16),

                      // ITEM PESANAN
                      _buildSection(context, 
                        'Item Pesanan (${latestOrder.items.length} produk)',
                        latestOrder.items.isEmpty
                            ? [_buildInfoRow(context, Icons.info_outline_rounded, 'Catatan', 'Detail item tidak tersedia')]
                            : latestOrder.items.map((item) => _buildItemRow(context, item)).toList(),
                      ),

                      SizedBox(height: 16),

                      // TOTAL BAYAR
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.surface, borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textGrey,
                              ),
                            ),
                            Text(
                              latestOrder.formattedTotal,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.colors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Fungsi pembantu untuk membuat kotak informasi waktu pengambilan
  Widget _buildPickupTimeSection(BuildContext context, OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: order.hasPickupTime
              ? context.colors.primaryOrange.withValues(alpha: 0.30)
              : context.colors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primaryOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: context.colors.primaryOrange,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jam Pengambilan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textGrey,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  order.hasPickupTime ? order.pickupTime! : 'Belum ditentukan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: order.hasPickupTime
                        ? context.colors.primaryOrange
                        : context.colors.textHint,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isSavingTime ? null : _pickDateTime,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.primaryOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: _isSavingTime
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: context.colors.primaryOrange,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      order.hasPickupTime ? 'Ubah' : 'Atur',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primaryOrange,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk membuat blok seksi informasi
  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.colors.textDark,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // Fungsi pembantu untuk menggambar baris informasi label dan value
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primaryOrange, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textGrey,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: context.colors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk merender data produk di dalam pesanan (beserta konversi base64/jaringan)
  Widget _buildItemRow(BuildContext context, OrderItemModel item) {
    final String imgUrl = item.imageUrl;
    final bool isBase64 = imgUrl.startsWith('data:image');
    final bool hasImage = imgUrl.isNotEmpty;

    Widget imageWidget;
    if (!hasImage) {
      imageWidget = Icon(
        Icons.bakery_dining_rounded,
        color: context.colors.primaryOrange,
        size: 18,
      );
    } else if (isBase64) {
      try {
        final bytes = base64Decode(imgUrl.split(',').last);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          errorBuilder: (_, __, ___) => Icon(
            Icons.bakery_dining_rounded,
            color: context.colors.primaryOrange,
            size: 18,
          ),
        );
      } catch (_) {
        imageWidget = Icon(
          Icons.bakery_dining_rounded,
          color: context.colors.primaryOrange,
          size: 18,
        );
      }
    } else {
      imageWidget = Image.network(
        imgUrl,
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        errorBuilder: (_, __, ___) => Icon(
          Icons.bakery_dining_rounded,
          color: context.colors.primaryOrange,
          size: 18,
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: context.colors.primaryOrange,
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.primaryOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageWidget,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName.isNotEmpty
                      ? item.productName
                      : 'Produk #${item.productId}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textDark,
                  ),
                ),
                Text(
                  '${item.quantity}x  •  Rp ${item.price.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: context.colors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${(item.price * item.quantity).toInt()}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.colors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
