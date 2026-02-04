# Conceptual Entity Relationship Diagram (ERD) - Roti 515

Berdasarkan struktur model OOP yang ada di dalam project `lib/core/models/`, berikut adalah bentuk representasi *Entity Relationship Diagram* (ERD) konseptualnya.

```mermaid
erDiagram
    %% Inheritance represented as 1 to 1 for simplicity in Mermaid, 
    %% but conceptually Admin and Pelanggan ARE Users.
    USER {
        int id PK
        string nama
        string email
        string password
    }

    ADMIN {
        int user_id PK, FK "Inherits from User"
        string level
    }

    PELANGGAN {
        int user_id PK, FK "Inherits from User"
        string no_hp
        datetime tgl_daftar
    }

    PRODUK {
        int id PK
        string nama
        int harga
        int stok
        string gambar
    }

    JADWAL_AMBIL {
        int id PK
        string jam_mulai
        string jam_selesai
        boolean is_aktif
    }

    KERANJANG {
        int id PK
        int pelanggan_id FK
    }

    KERANJANG_ITEM {
        int keranjang_id PK, FK
        int produk_id PK, FK
        int qty
    }

    ORDER {
        int id PK
        int pelanggan_id FK
        string status
        float total
        string jam_ambil
        string metode_bayar
    }

    ITEM_ORDER {
        int order_id PK, FK
        int produk_id PK, FK
        int qty
        float harga_satuan
    }

    %% Relationships
    USER ||--|| ADMIN : merupakan
    USER ||--|| PELANGGAN : merupakan

    PELANGGAN ||--o| KERANJANG : has
    KERANJANG ||--o{ KERANJANG_ITEM : contains
    PRODUK ||--o{ KERANJANG_ITEM : added_to

    PELANGGAN ||--o{ ORDER : makes
    ORDER ||--|{ ITEM_ORDER : contains
    PRODUK ||--o{ ITEM_ORDER : part_of

    ADMIN ||--o{ PRODUK : manages
    ADMIN ||--o{ JADWAL_AMBIL : configures
    ADMIN ||--o{ ORDER : processes

```

### Penjelasan Relasi:
1. **Inheritance (Pewarisan)**: `ADMIN` dan `PELANGGAN` adalah turunan dari `USER`. Mereka memiliki semua atribut dari `USER` ditambah atribut spesifik mereka sendiri.
2. **Pelanggan & Keranjang**: Seorang `PELANGGAN` dapat memiliki 1 `KERANJANG` (One-to-One / One-to-Zero-or-One).
3. **Keranjang & Keranjang Item**: `KERANJANG` dapat berisi banyak `KERANJANG_ITEM` (One-to-Many). `KERANJANG_ITEM` bertindak sebagai *pivot table* yang menghubungkan `KERANJANG` dan `PRODUK`.
4. **Pelanggan & Order**: Seorang `PELANGGAN` dapat membuat banyak `ORDER` (One-to-Many).
5. **Order & Item Order**: Sebuah `ORDER` terdiri dari banyak `ITEM_ORDER` (One-to-Many). Sama seperti keranjang, `ITEM_ORDER` adalah tabel pivot antara `ORDER` dan `PRODUK`.
6. **Admin**: Secara operasional (berdasarkan *method* pada model `Admin`), Admin mengelola `PRODUK`, mengatur `JADWAL_AMBIL`, dan memproses `ORDER`.
