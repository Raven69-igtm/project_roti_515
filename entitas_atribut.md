# Kamus Data: Entitas dan Atribut - Roti 515

Berikut adalah penjabaran detail dari setiap entitas beserta atribut-atributnya berdasarkan ERD konseptual yang telah dibuat sebelumnya.

### 1. Entitas: USER (Abstrak)
Entitas ini merupakan entitas dasar/induk untuk semua jenis pengguna dalam sistem.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | Integer | **Primary Key** - Identifier unik pengguna |
| `nama` | String / Varchar | Nama lengkap pengguna |
| `email` | String / Varchar | Alamat email pengguna |
| `password` | String / Varchar | Kata sandi untuk login |

### 2. Entitas: ADMIN
Entitas ini mewarisi atribut dari entitas `USER` dan merepresentasikan pengelola sistem.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `user_id` | Integer | **Primary Key, Foreign Key** - Mengacu pada `USER(id)` |
| `level` | String / Varchar | Tingkat hak akses admin (misal: 'superadmin', 'admin') |

### 3. Entitas: PELANGGAN
Entitas ini mewarisi atribut dari entitas `USER` dan merepresentasikan konsumen yang menggunakan aplikasi.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `user_id` | Integer | **Primary Key, Foreign Key** - Mengacu pada `USER(id)` |
| `no_hp` | String / Varchar | Nomor telepon aktif pelanggan |
| `tgl_daftar` | DateTime | Tanggal dan waktu pelanggan mendaftar |

### 4. Entitas: PRODUK
Menyimpan informasi tentang roti atau barang yang dijual.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | Integer | **Primary Key** - Identifier unik produk |
| `nama` | String / Varchar | Nama produk/roti |
| `harga` | Integer / Float | Harga jual produk |
| `stok` | Integer | Jumlah ketersediaan produk saat ini |
| `gambar` | String / Varchar | URL atau path dari gambar produk |

### 5. Entitas: JADWAL_AMBIL
Mewakili opsi waktu yang bisa dipilih pelanggan untuk mengambil pesanannya.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | Integer | **Primary Key** - Identifier unik jadwal |
| `jam_mulai` | String / Time | Waktu awal pengambilan (misal: "10:00") |
| `jam_selesai` | String / Time | Waktu akhir batas pengambilan (misal: "11:00") |
| `is_aktif` | Boolean | Status apakah jadwal ini sedang tersedia atau tidak |

### 6. Entitas: KERANJANG
Keranjang belanja virtual untuk masing-masing pelanggan.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | Integer | **Primary Key** - Identifier unik keranjang |
| `pelanggan_id` | Integer | **Foreign Key** - Mengacu pada `PELANGGAN(user_id)` |

### 7. Entitas: KERANJANG_ITEM
Merupakan tabel relasi (pivot) untuk mencatat produk apa saja dan berapa jumlahnya di dalam sebuah keranjang.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `keranjang_id` | Integer | **Primary Key, Foreign Key** - Mengacu pada `KERANJANG(id)` |
| `produk_id` | Integer | **Primary Key, Foreign Key** - Mengacu pada `PRODUK(id)` |
| `qty` | Integer | Jumlah (kuantitas) produk tersebut di dalam keranjang |

### 8. Entitas: ORDER
Menyimpan riwayat dan status transaksi pesanan yang telah di-checkout.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | Integer | **Primary Key** - Identifier unik pesanan |
| `pelanggan_id` | Integer | **Foreign Key** - Mengacu pada `PELANGGAN(user_id)` |
| `status` | String / Varchar | Status pesanan (misal: "pending", "dikonfirmasi", "selesai") |
| `total` | Float / Decimal | Total nominal yang harus dibayar |
| `jam_ambil` | String / Varchar | Waktu pengambilan yang dipilih pelanggan |
| `metode_bayar` | String / Varchar | Metode pembayaran yang digunakan (misal: "Cash") |

### 9. Entitas: ITEM_ORDER
Merupakan tabel relasi (pivot) untuk mencatat detail produk yang dibeli dalam satu Order tertentu.

| Nama Atribut | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `order_id` | Integer | **Primary Key, Foreign Key** - Mengacu pada `ORDER(id)` |
| `produk_id` | Integer | **Primary Key, Foreign Key** - Mengacu pada `PRODUK(id)` |
| `qty` | Integer | Jumlah (kuantitas) produk yang dibeli |
| `harga_satuan` | Float / Decimal | Harga produk saat transaksi terjadi (historical price) |
