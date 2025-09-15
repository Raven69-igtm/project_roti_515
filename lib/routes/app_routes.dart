import 'package:flutter/material.dart';

// --- IMPORT SEMUA SCREEN ---
import '../features/main_nav/screens/main_nav_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/cart/screens/checkout_screen.dart';
import '../features/cart/screens/checkout_success_screen.dart';
// ✅ Tambahkan import untuk halaman Admin
import '../features/admin/dashboard/screens/admin_main_nav_screen.dart'; 
// Import login success screen
import '../features/auth/screens/login_success_screen.dart';
// Import register success screen
import '../features/auth/screens/register_success_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/profile/screens/privacy_policy_screen.dart';
import '../features/profile/screens/terms_conditions_screen.dart';

import '../presentation/pages/splash/splash_screen.dart';

class AppRoutes {
  // 1. DAFTAR NAMA RUTE (String)
  static String splash = '/splash';
  static String mainNav = '/';
  static String login = '/login';
  static String register = '/register';
  static String cart = '/cart';
  static String checkout = '/checkout';
  static String checkoutSuccess = '/checkout-success';
  // ✅ Tambahkan nama rute Admin
  static String adminDashboard = '/admin_dashboard'; 
  
  static String loginSuccess = '/login-success';
  static String registerSuccess = '/register-success';
  static String forgotPassword = '/forgot-password';
  static String resetPassword = '/reset-password';
  static String privacyPolicy = '/privacy-policy';
  static String termsConditions = '/terms-conditions';

  // 2. BUKU TELEPON (Mapping Rute ke Screen)
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => SplashScreen(),
      mainNav: (context) => MainNavScreen(),
      login: (context) => LoginScreen(),
      register: (context) => RegisterScreen(),
      cart: (context) => CartScreen(),
      checkout: (context) => CheckoutScreen(),
      checkoutSuccess: (context) {
        final ref = ModalRoute.of(context)!.settings.arguments as String?;
        return CheckoutSuccessScreen(
          orderRef: ref ?? generateOrderRef(),
        );
      },
      // ✅ Daftarkan halaman Admin ke dalam peta navigasi
      adminDashboard: (context) => AdminMainNavScreen(), 
      loginSuccess: (context) => LoginSuccessScreen(),
      registerSuccess: (context) => RegisterSuccessScreen(),
      forgotPassword: (context) => ForgotPasswordScreen(),
      resetPassword: (context) => ResetPasswordScreen(),
      privacyPolicy: (context) => PrivacyPolicyScreen(),
      termsConditions: (context) => TermsConditionsScreen(),
    };
  }
}
