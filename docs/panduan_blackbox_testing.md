# PANDUAN PENGUJIAN BLACK BOX (BLACK BOX TESTING GUIDE)
## APLIKASI ROTI 515

Dokumen ini menjelaskan strategi, teknik, dan skenario pengujian *Black Box* (atau *User Acceptance Testing* - UAT) untuk proyek aplikasi **Roti 515** (Sistem Pemesanan Roti Online). Dokumen ini dirancang agar dapat langsung dimasukkan ke dalam Laporan Proyek atau digunakan oleh tim penguji untuk memverifikasi fungsionalitas sistem.

---

## 1. Pendahuluan & Konsep Utama

**Black Box Testing** adalah metode pengujian perangkat lunak di mana fungsionalitas aplikasi diuji tanpa harus mengetahui struktur kode internal, detail implementasi, atau arsitektur database-nya. 

Pada proyek **Roti 515**, pengujian berfokus pada:
1. **Kesesuaian Fungsional:** Apakah sistem merespons input pengguna (baik Customer maupun Admin) sesuai dengan spesifikasi fungsional (Product Backlog).
2. **Validasi Alur Bisnis (End-to-End):** Memastikan proses pemesanan dari pemilihan roti, pembayaran/checkout, hingga pemrosesan oleh Admin berjalan tanpa hambatan.
3. **Keandalan UI/UX:** Memastikan responsivitas tampilan (responsif di berbagai perangkat menggunakan `DevicePreview`) dan transisi antar state berjalan lancar.

---

## 2. Ruang Lingkup Pengujian (Scope)

Pengujian mencakup dua peran utama dalam sistem:

### A. Fitur Sisi Customer (Pelanggan)
* **Autentikasi:** Registrasi Akun baru dan Login (kredensial email & password).
* **Katalog Produk:** Pencarian produk, penayangan produk unggulan (Bestsellers), dan detail produk.
* **Keranjang (Cart):** Tambah ke keranjang, ubah kuantitas, validasi batas stok, dan hapus item.
* **Favorit:** Menyimpan produk favorit (*toggling*).
* **Checkout:** Pengisian data pesanan, pemilihan metode pembayaran, pengaturan waktu/jadwal pengambilan, dan penayangan kode referensi unik (`#ROTI515-XXXXX`).
* **Riwayat Pesanan & Notifikasi:** Melacak perubahan status pesanan secara real-time dan pembatalan pesanan yang belum diproses.

### B. Fitur Sisi Admin (Administrator)
* **Dashboard Admin:** Pemantauan statistik harian dan ringkasan transaksi.
* **Manajemen Produk:** Menambah (*Create*), mengedit (*Update*), menghapus (*Delete*), serta memperbarui stok produk roti.
* **Manajemen Pesanan:** Memantau pesanan masuk secara real-time, mengonfirmasi pesanan, dan mengubah status pengerjaan (`Diproses` / `Siap Diambil` / `Selesai`).

---

## 3. Teknik Black Box Testing yang Diterapkan

Untuk memastikan kualitas pengujian, kita menerapkan empat teknik Black Box utama:

### 1. Equivalence Partitioning (EP)
Membagi domain input ke dalam kelas-kelas data untuk menguji nilai yang valid dan tidak valid.
* **Contoh pada Roti 515:**
  * **Input Valid:** Format email yang benar (`user@example.com`) ➔ Hasil: Berhasil login/registrasi.
  * **Input Tidak Valid:** Format email tanpa `@` (`userexample.com`) ➔ Hasil: Sistem menampilkan pesan error "Format email tidak valid".

### 2. Boundary Value Analysis (BVA)
Fokus pada batas-batas ekstrem dari input data.
* **Contoh pada Roti 515:**
  * **Stok Roti:** Sisa stok roti di database adalah **5 buah**.
  * **Batas bawah (Valid):** Input kuantitas **1** dan **5** ➔ Hasil: Berhasil ditambahkan ke keranjang.
  * **Batas atas (Tidak Valid):** Input kuantitas **6** (stok + 1) ➔ Hasil: Tombol tambah terkunci atau muncul peringatan "Kuantitas pesanan melebihi sisa stok".

### 3. State Transition Testing
Menguji transisi status aplikasi ketika terjadi aksi tertentu. Sangat penting untuk melacak siklus pesanan (*order lifecycle*).
* **Alur Transisi Status Pesanan:**
  * `Menunggu Pembayaran` ➔ User klik Batalkan ➔ `Dibatalkan` (Valid).
  * `Menunggu Pembayaran` ➔ Admin konfirmasi ➔ `Diproses` (Valid).
  * `Diproses` ➔ User klik Batalkan ➔ (Tidak diizinkan/tombol batal hilang).
  * `Diproses` ➔ Admin klik Siap Diambil ➔ `Siap Diambil` (Valid).
  * `Siap Diambil` ➔ Admin klik Selesai ➔ `Selesai` (Valid).

### 4. Use Case (End-to-End) Testing
Menguji skenario dunia nyata dari awal hingga akhir dengan melibatkan kolaborasi antar aktor (Customer & Admin).
* **Alur Skenario:** Customer melakukan login ➔ memilih produk ➔ melakukan checkout ➔ Admin menerima notifikasi pesanan masuk di dashboard ➔ Admin memproses pesanan ➔ Customer mendapatkan notifikasi perubahan status ➔ Customer mengambil roti dan Admin menandai selesai.

---

## 4. Contoh Tabel Skenario Pengujian (Test Cases)

Berikut adalah tabel skenario uji fungsionalitas aplikasi Roti 515 yang dapat diadopsi ke dalam laporan pengujian:

### Modul A: Autentikasi & Profil (Iterasi 1)

| ID Test | Fitur | Skenario Pengujian | Prosedur Pengujian | Ekspektasi Hasil | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T1-01** | Login | Login dengan kredensial kosong. | 1. Kosongkan field Email dan Password.<br>2. Klik tombol "Masuk". | Muncul snackbar peringatan "Email dan Password wajib diisi". | **Selesai** |
| **T1-02** | Login | Login dengan format email salah. | 1. Input email `admin.roti` (tanpa `@`).<br>2. Input password.<br>3. Klik tombol "Masuk". | Muncul snackbar/pesan error bahwa format email tidak valid. | **Selesai** |
| **T1-03** | Login | Login dengan akun Admin yang valid. | 1. Input email & password Admin yang terdaftar.<br>2. Klik tombol "Masuk". | Berhasil masuk dan langsung diarahkan ke Dashboard Admin. | **Selesai** |
| **T1-04** | Login | Login dengan akun Customer yang valid. | 1. Input email & password Customer yang terdaftar.<br>2. Klik tombol "Masuk". | Berhasil masuk dan diarahkan ke halaman Utama/Katalog Pelanggan. | **Selesai** |
| **T1-05** | Profil | Mengedit data profil (alamat & no. telp). | 1. Buka tab Profil.<br>2. Isi nama, alamat, no. telepon baru.<br>3. Klik "Simpan Perubahan". | Data tersimpan lokal via Shared Preferences, UI profil langsung diperbarui. | **Selesai** |

### Modul B: Transaksi & Pemesanan (Iterasi 2)

| ID Test | Fitur | Skenario Pengujian | Prosedur Pengujian | Ekspektasi Hasil | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T2-01** | Keranjang | Menambahkan roti ke dalam keranjang. | 1. Buka detail roti.<br>2. Atur kuantitas pembelian.<br>3. Klik "Tambah ke Keranjang". | Produk masuk ke keranjang, lencana jumlah pada ikon keranjang bertambah. | **Selesai** |
| **T2-02** | Keranjang | Validasi batas maksimum stok di keranjang. | 1. Buka keranjang.<br>2. Klik "+" hingga melampaui jumlah stok tersedia. | Tombol "+" terkunci atau memicu peringatan kuantitas melebihi stok. | **Selesai** |
| **T2-03** | Checkout | Melakukan checkout dengan data lengkap. | 1. Di keranjang klik "Lanjutkan ke Checkout".<br>2. Isi detail, pilih metode bayar & jam ambil.<br>3. Klik "Checkout". | Halaman sukses transaksi muncul dan menghasilkan kode referensi `#ROTI515-XXXXX`. | **Selesai** |
| **T2-04** | Pembatalan | Membatalkan pesanan yang belum diproses. | 1. Buka Riwayat Pesanan.<br>2. Pilih status "Menunggu Pembayaran".<br>3. Klik "Batalkan Pesanan". | Status pesanan berubah menjadi "Dibatalkan" dan tombol pembatalan dinonaktifkan. | **Selesai** |
| **T2-05** | Admin | Admin mengubah status pengerjaan pesanan. | 1. Login Admin.<br>2. Buka Manajemen Pesanan.<br>3. Ubah status pesanan pelanggan jadi "Diproses". | Status pesanan di database admin berubah, notifikasi terkirim real-time ke Customer. | **Selesai** |

---

## 5. Cara Melakukan Eksekusi Pengujian

### A. Pengujian Manual (Manual Testing)
Pengujian manual dilakukan secara langsung oleh tester pada perangkat/aplikasi:
1. **Lingkungan Pengujian:** Gunakan emulator Android, simulator iOS, atau browser web (akses [https://roti515.up.railway.app](https://roti515.up.railway.app)).
2. **DevicePreview:** Aktifkan simulator layar bawaan (`DevicePreview`) dalam mode debug untuk memverifikasi responsivitas UI pada ukuran layar yang berbeda (dari resolusi HP kecil, tablet, hingga web desktop).
3. **Dokumentasi Hasil:** Catat setiap hasil pengujian ke dalam tabel laporan pengujian dengan melampirkan screenshot sebagai bukti (*evidence*).

### B. Pengujian Otomatis (Automated UI/Integration Testing)
Flutter menyediakan paket `integration_test` untuk menulis script pengujian Black Box otomatis yang mensimulasikan tindakan pengguna nyata.

**Cara Membuat Pengujian UI Otomatis di Flutter:**
1. Tambahkan dependensi di `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     integration_test:
       sdk: flutter
     flutter_test:
       sdk: flutter
   ```
2. Buat file uji di direktori `integration_test/app_test.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:integration_test/integration_test.dart';
   import 'package:roti_515/main.dart' as app;

   void main() {
     IntegrationTestWidgetsFlutterBinding.ensureInitialized();

     testWidgets("Skenario Black Box: Gagal Login karena form kosong", (tester) async {
       app.main(); // Menjalankan aplikasi
       await tester.pumpAndSettle(); // Tunggu sampai splash screen selesai

       // Mencari tombol masuk/login tanpa mengisi input
       final Finder loginButton = find.byType(ElevatedButton); // atau cari berdasarkan Text/Key
       await tester.tap(loginButton);
       await tester.pumpAndSettle();

       // Verifikasi apakah snackbar error muncul
       expect(find.text("Email dan Password wajib diisi"), findsOneWidget);
     });
   }
   ```
3. Jalankan tes otomatis dengan perintah berikut di terminal:
   ```bash
   flutter test integration_test/app_test.dart
   ```
