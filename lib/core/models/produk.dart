class Produk {
  int _id;
  String _nama;
  int _harga;
  int _stok;
  String _gambar;

  Produk({
    required int id,
    required String nama,
    required int harga,
    required int stok,
    required String gambar,
  })  : _id = id,
        _nama = nama,
        _harga = harga,
        _stok = stok,
        _gambar = gambar;

  // Encapsulation: Getters
  int get id => _id;
  String get nama => _nama;
  int get harga => _harga;
  int get stok => _stok;
  String get gambar => _gambar;

  // Encapsulation: Setter
  set stok(int value) => _stok = value;

  void tampilDetail() {
    print('Produk: $_nama, Harga: $_harga, Stok: $_stok');
  }

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'] ?? 0,
      nama: json['name'] ?? '',
      harga: (json['price'] ?? 0).toInt(),
      stok: json['stock'] ?? 0,
      gambar: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _nama,
      'price': _harga,
      'stock': _stok,
      'image_url': _gambar,
    };
  }
}
