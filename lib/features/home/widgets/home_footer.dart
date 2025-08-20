import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:roti_515/core/theme/app_theme.dart';


class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Seksi
          Text(
            "Our Location & Socials",
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 24,
              color: context.colors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),

          // 1. BAGIAN PETA (Interactive Map or Fallback Image)
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: _MapContentView(),
                ),
              ),
              // Overlay Button Maps
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Maps",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: context.colors.textDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // 2. KARTU ALAMAT (Visit Us)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: context.colors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.primaryOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: context.colors.primaryOrange,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "VISIT US",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: context.colors.textHint,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Kemlokolegi, Kec. Baron, Kabupaten Nganjuk, Jawa Timur, Indonesia",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),

          // 3. MEDIA SOSIAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Follow us",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark,
                ),
              ),
              Row(
                children: [
                  _buildSocialBtn(
                    FontAwesomeIcons.whatsapp,
                    Color(0xfff0fdf4),
                    Color(0xff25d366),
                    "https://wa.me/6285940947728",
                  ), // WA
                  SizedBox(width: 12),
                  _buildSocialBtn(
                    FontAwesomeIcons.tiktok,
                    Color(0xfff1f5f9),
                    Color(0xff000000),
                    "https://www.tiktok.com/@roti_515?_r=1&_t=ZS-95sTutxFLWb",
                  ), // TikTok
                  SizedBox(width: 12),
                  _buildSocialBtn(
                    FontAwesomeIcons.facebook,
                    Color(0xffeff6ff),
                    Color(0xff1877f2),
                    "https://m.facebook.com/?next=https%3A%2F%2Fm.facebook.com%2Fshare%2F1DtpiErtbe%2F%3Fmibextid%3DwwXIfr%26wtsid%3Drdr_0dgcHvV50By3NNHpd",
                  ), // FB
                ],
              ),
            ],
          ),
          SizedBox(height: 40),

          Divider(color: context.colors.divider),
          SizedBox(height: 20),

          Center(
            child: Text(
              "© 2026 Roti 515 - Baked with Passion",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: context.colors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, Color bg, Color iconColor, String url) {
    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse(url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Could not launch $url: $e');
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Center(
          child: FaIcon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _MapContentView extends StatelessWidget {
  const _MapContentView();

  // URL Google Maps untuk dibuka di aplikasi/browser
  final String _googleMapsUrl = 'https://maps.app.goo.gl/sK5XzhsLK179oXfw6';

  Future<void> _launchMaps() async {
    try {
      final Uri url = Uri.parse(_googleMapsUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(viewType: 'google-maps-embed');
    }

    // Tampilan untuk Android/iOS
    return GestureDetector(
      onTap: _launchMaps, // Tekan untuk buka Google Maps asli
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/map_colored.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Color(0xFFF1F5F9),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  color: Color(0xFF94A3B8),
                  size: 40,
                ),
              ),
            ),
          ),
          // Indikator bahwa ini bisa diklik
          Container(
            color: Colors.black.withValues(alpha: 0.05),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Klik untuk Petunjuk Arah",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
