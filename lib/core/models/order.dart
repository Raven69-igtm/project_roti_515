class ItemOrder {
  int _orderId;
  int _produkId;
  int _qty;
  double _hargaSatuan;

  ItemOrder({
    required int orderId,
    required int produkId,
    required int qty,
    required double hargaSatuan,
  })  : _orderId = orderId,
        _produkId = produkId,
        _qty = qty,
        _hargaSatuan = hargaSatuan;

  int get orderId => _orderId;
  int get produkId => _produkId;
  int get qty => _qty;
  double get hargaSatuan => _hargaSatuan;

  double getSubtotal() => _qty * _hargaSatuan;
}

class Order {
  int _id;
  String _status;
  double _total;
  String _jamAmbil;
  String _metodeBayar;

  Order({
    required int id,
    required String status,
    required double total,
    required String jamAmbil,
    required String metodeBayar,
  })  : _id = id,
        _status = status,
        _total = total,
        _jamAmbil = jamAmbil,
        _metodeBayar = metodeBayar;

  int get id => _id;
  String get status => _status;
  double get total => _total;
  String get jamAmbil => _jamAmbil;
  String get metodeBayar => _metodeBayar;

  set status(String value) => _status = value;

  void konfirmasi() {
    _status = 'dikonfirmasi';
  }

  void batalkan() {
    _status = 'dibatalkan';
  }
}
