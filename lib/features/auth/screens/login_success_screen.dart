import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

/// Halaman sukses yang ditampilkan setelah user berhasil login.
class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen>
    with TickerProviderStateMixin {
  // --- KONTROLER ANIMASI ---
  
  // 1. Animasi lingkaran sukses (skala & transparansi)
  late final AnimationController _circleCtrl;
  late final Animation<double> _circleScale;
  late final Animation<double> _circleFade;

  // 2. Animasi teks informasi (muncul meluncur dari bawah)
  late final AnimationController _textCtrl;
  late final Animation<double> _textSlide;
  late final Animation<double> _textFade;

  // 3. Animasi tombol interaksi (muncul di akhir)
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnFade;
  late final Animation<double> _btnSlide;

  @override
  void initState() {
    super.initState();

    // ── STEP 1: INISIALISASI ANIMASI IKON (Efek Elastis) ───────────────────
    _circleCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _circleScale = CurvedAnimation(
      parent: _circleCtrl,
      curve: Curves.elasticOut, // Efek membal saat muncul
    );
    _circleFade = CurvedAnimation(
      parent: _circleCtrl,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    // ── STEP 2: INISIALISASI ANIMASI TEKS (Efek Meluncur) ──────────────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _textSlide = Tween<double>(begin: 30, end: 0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_textCtrl);
    _textFade = CurvedAnimation(
      parent: _textCtrl,
      curve: Curves.easeOut,
    );

    // ── STEP 3: INISIALISASI ANIMASI TOMBOL ───────────────────────────────
    _btnCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut);
    _btnSlide = Tween<double>(begin: 20, end: 0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_btnCtrl);

    // Menjalankan urutan animasi secara otomatis saat halaman dibuka
    _runSequence();
  }

  /// FUNGSI RUN SEQUENCE:
  /// Mengatur waktu tunggu agar animasi muncul satu per satu (Sekuensial).
  Future<void> _runSequence() async {
    await Future.delayed(Duration(milliseconds: 150));
    if (!mounted) return;
    _circleCtrl.forward(); // Jalankan animasi ikon
    await Future.delayed(Duration(milliseconds: 400));
    if (!mounted) return;
    _textCtrl.forward(); // Jalankan animasi teks
    await Future.delayed(Duration(milliseconds: 300));
    if (!mounted) return;
    _btnCtrl.forward(); // Jalankan animasi teks bawah

    // Auto-redirect ke beranda setelah 2 detik
    await Future.delayed(Duration(seconds: 2));
    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      await Provider.of<AuthProvider>(context, listen: false).login(
        args['token'],
        role: args['role'],
        name: args['name'],
        photoUrl: args['photoUrl'],
      );
    }

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  void dispose() {
    // Membersihkan semua kontroler animasi agar tidak memakan memori (Memory Leak)
    _circleCtrl.dispose();
    _textCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.authBackground,
      body: Stack(
        children: [
          // Latar belakang dengan gradasi halus (Custom Painter)
          Positioned.fill(
            child: CustomPaint(painter: _RadialBgPainter(context.colors.primaryOrange)),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Spacer(flex: 2),

                  // WIDGET IKON SUKSES (Dibatasi Animasi Transisi)
                  ScaleTransition(
                    scale: _circleScale,
                    child: FadeTransition(
                      opacity: _circleFade,
                      child: _SuccessIcon(),
                    ),
                  ),

                  SizedBox(height: 32),

                  // WIDGET INFORMASI TEKS (AnimatedBuilder untuk efek Slide)
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: FadeTransition(
                        opacity: _textFade,
                        child: child,
                      ),
                    ),
                    child: _LoginInfo(),
                  ),

                  Spacer(flex: 3),

                  // WIDGET TEKS REDIRECT OTOMATIS
                  AnimatedBuilder(
                    animation: _btnCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _btnSlide.value),
                      child: FadeTransition(
                        opacity: _btnFade,
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.primaryOrange,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Mengalihkan ke beranda...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.colors.textHint,
                              height: 20 / 14,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'roti515',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.colors.textHint,
                              height: 20 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CUSTOM PAINTER: Membuat efek cahaya gradasi di latar belakang.
class _RadialBgPainter extends CustomPainter {
  final Color color;
  _RadialBgPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.75,
        colors: [
          color.withValues(alpha: 0.06),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// SUCCESS ICON: Widget visual ikon centang hijau.
class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    Color greenColor = context.colors.success;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: greenColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: greenColor,
        size: 50,
      ),
    );
  }
}

/// LOGIN INFO: Berisi teks judul dan ucapan selamat datang.
class _LoginInfo extends StatelessWidget {
  const _LoginInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Login Berhasil',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: context.colors.textDark,
            height: 40 / 32,
          ),
        ),
        SizedBox(height: 8),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Selamat Datang Di ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: context.colors.textGrey,
                  height: 28 / 18,
                ),
              ),
              TextSpan(
                text: 'roti515',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


