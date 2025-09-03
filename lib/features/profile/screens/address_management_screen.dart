import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/utils/premium_snackbar.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class AddressManagementScreen extends StatefulWidget {
  final String currentAddress;
  const AddressManagementScreen({super.key, required this.currentAddress});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  late TextEditingController _addressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Menginisialisasi input teks dengan alamat saat ini (dikosongkan jika nilainya masih 'Ambil Di Toko')
    _addressController = TextEditingController(text: widget.currentAddress == "Ambil Di Toko" ? "" : widget.currentAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Menyimpan alamat pengiriman baru ke server/API backend
  Future<void> _saveAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Alamat tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      // Mengirim PUT request ke backend untuk meng-update field address user
      final response = await http.put(
        Uri.parse(ApiService.profile),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "address": address,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        // Memperbarui cache alamat di AuthProvider lokal agar sinkron
        Provider.of<AuthProvider>(context, listen: false).updateProfileData(address: address);
        PremiumSnackbar.showSuccess(context, "Alamat berhasil disimpan");
        Navigator.pop(context, address);
      } else {
        throw Exception("Gagal menyimpan alamat");
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, "Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        backgroundColor: context.colors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Alamat Lengkap",
          style: GoogleFonts.plusJakartaSans(
            color: context.colors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukkan Alamat Pengiriman",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textDark.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                controller: _addressController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Contoh: Jl. Mawar No. 123, Denpasar, Bali",
                  hintStyle: GoogleFonts.plusJakartaSans(color: context.colors.textHint, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(20),
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: context.colors.textDark),
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Simpan Alamat",
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
