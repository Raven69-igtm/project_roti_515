import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/network/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Widget Bottom Sheet untuk memberi rating pada produk setelah pesanan selesai.
class RatingDialog extends StatefulWidget {
  final int orderId;
  final int foodId;
  final String foodName;

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.foodId,
    required this.foodName,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedRating = 0; // 1–5 bintang
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting || _submitted) return; // Proteksi ganda dari sisi state

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pilih bintang rating terlebih dahulu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.post(
        Uri.parse(ApiService.ratingByFoodId(widget.foodId)),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "rating": _selectedRating,
          "order_id": widget.orderId,
          if (_commentController.text.trim().isNotEmpty)
            "comment": _commentController.text.trim(),
        }),
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _submitted = true;
            _isSubmitting = false;
          });
          // Tutup bottom sheet setelah 1.5 detik
          await Future.delayed(Duration(milliseconds: 1500));
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal mengirim rating (${response.statusCode})"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Judul
          Text(
            "Beri Rating",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            widget.foodName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),

          SizedBox(height: 24),

          // Bintang interaktif
          if (!_submitted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = starIndex),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      starIndex <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 48,
                      color: starIndex <= _selectedRating
                          ? Colors.amber.shade500
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: 8),
            Text(
              _selectedRating == 0
                  ? "Ketuk bintang untuk memberi nilai"
                  : _ratingLabel(_selectedRating),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: _selectedRating == 0
                    ? Colors.grey.shade400
                    : Colors.amber.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 20),

            // Kolom komentar opsional
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 200,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Tambahkan komentar (opsional)...",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Tombol submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD47311),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                        "Kirim Rating",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Tampilan sukses
            Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, size: 40, color: Colors.green.shade500),
                ),
                SizedBox(height: 16),
                Text(
                  "Terima kasih atas rating Anda!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _selectedRating,
                    (_) => Icon(Icons.star_rounded, color: Colors.amber.shade500, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return "Sangat Buruk 😞";
      case 2: return "Buruk 😕";
      case 3: return "Cukup 😐";
      case 4: return "Bagus 😊";
      case 5: return "Sangat Bagus! 🤩";
      default: return "";
    }
  }
}
