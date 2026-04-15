import 'produk.dart';

class KeranjangItem {
  int _keranjangId;
  int _produkId;
  int _qty;

  KeranjangItem({
    required int keranjangId,
    required int produkId,
    required int qty,
  })  : _keranjangId = keranjangId,
        _produkId = produkId,
        _qty = qty;

  int get keranjangId => _keranjangId;
  int get produkId => _produkId;
  int get qty => _qty;

  set qty(int value) => _qty = value;
}

class Keranjang {
  int _id;
  int _pelangganId;
  List<KeranjangItem> _items;

  Keranjang({
    required int id,
    required int pelangganId,
    required List<KeranjangItem> items,
  })  : _id = id,
        _pelangganId = pelangganId,
        _items = items;

  int get id => _id;
  int get pelangganId => _pelangganId;
  List<KeranjangItem> get items => _items;

  void tambahItem(Produk produk, int qty) {
    _items.add(KeranjangItem(keranjangId: _id, produkId: produk.id, qty: qty));
  }

  void hapusItem(int produkId) {
    _items.removeWhere((item) => item.produkId == produkId);
  }

  double hitungTotal() {
    // Note: In real app, we'd need prices. For now, matching diagram.
    return 0.0;
  }
}
