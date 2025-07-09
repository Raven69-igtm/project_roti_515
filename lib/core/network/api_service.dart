/// ApiService: Sentralisasi rute/endpoint API aplikasi.
/// Digunakan agar kita tidak perlu menulis URL manual di setiap fitur.
class ApiService {
  /// Alamat dasar server API (Host) yang sedang digunakan.
  static String get baseUrl =>
      'https://roti515-api.vercel.app/api';

  /// Alamat Domain (tanpa rute /api) untuk memanggil resource statis seperti gambar.
  static String get baseDomain =>
      'https://roti515-api.vercel.app';

  // --- DAFTAR ENDPOINT AUTENTIKASI ---
  // Rute untuk melakukan login (POST)
  static String get login => '$baseUrl/login';
  // Rute untuk mendaftarkan akun baru (POST)
  static String get register => '$baseUrl/register';
  // Rute untuk memverifikasi identitas sebelum reset password (POST)
  static String get forgotPassword => '$baseUrl/forgot-password';
  // Rute untuk mereset password setelah verifikasi (POST)
  static String get resetPassword => '$baseUrl/reset-password';
  // Rute khusus untuk demo login via tombol Google (POST)
  static String get demoLogin => '$baseUrl/demo-login';

  // --- DAFTAR ENDPOINT LAINNYA ---
  static String get profile => '$baseUrl/profile';
  static String get uploadPhoto => '$baseUrl/profile/photo';
  static String get adminStats => '$baseUrl/admin/stats';
  static String get notifications => '$baseUrl/notifications';
  static String get foods => '$baseUrl/foods';
  static String get orders => '$baseUrl/orders'; 
  static String get userOrders => '$baseUrl/user/orders';
  static String get adminOrders => '$baseUrl/admin/orders';
  
  // Endpoint dinamis untuk update status pesanan berdasarkan ID
  static String adminOrderById(int id) => '$baseUrl/admin/orders/$id';
  static String get adminUsers => '$baseUrl/admin/users';

  // Endpoint untuk user: batalkan, hapus pesanan, dan rating
  static String cancelOrderById(int id) => '$baseUrl/orders/$id/cancel';
  static String confirmOrderPickupById(int id) => '$baseUrl/orders/$id/confirm';
  static String userOrderById(int id) => '$baseUrl/orders/$id';
  static String ratingByFoodId(int foodId) => '$baseUrl/foods/$foodId/rating';

  // Endpoint notifikasi per item
  static String notificationById(int id) => '$baseUrl/notifications/$id';
  static String get deleteAllNotifications => '$baseUrl/notifications/all';
  static String get deleteAllUserOrders => '$baseUrl/user/orders/all';

  // Endpoint rekap bulanan admin (filter by month & year)
  static String adminMonthlyStats(int month, int year) => '$baseUrl/admin/stats?month=$month&year=$year';

  /// Link Folder Statis di Server: Tempat semua gambar di-upload dan disimpan.
  static String get staticFiles => '$baseDomain/static/';

  /// FUNGSI RESOLUSI GAMBAR:
  /// Menjamin aplikasi mendapatkan URL gambar yang valid terlepas dari format DB.
  static String getDisplayImage(String? path) {
    if (path == null || path.isEmpty) return '';
    
    // 1. Jika path adalah Base64 Data URL (dari upload foto), kembalikan langsung.
    if (path.startsWith('data:image')) return path;

    // 2. Jika path sudah berupa URL lengkap (misal link Google), gunakan langsung.
    if (path.startsWith('http')) return path;

    // 3. Jika path diawali dengan '/static', gabungkan dengan baseDomain server.
    if (path.startsWith('/static')) {
      return '$baseDomain$path';
    }

    // 4. Jika hanya nama file (misal: 'roti.png'), tambahkan prefix folder static server.
    final cleaned = path.startsWith('/') ? path : '/$path';
    return '$baseDomain/static$cleaned';
  }
}
