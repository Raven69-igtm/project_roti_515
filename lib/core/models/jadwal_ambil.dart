class JadwalAmbil {
  int _id;
  String _jamMulai;
  String _jamSelesai;
  bool _isAktif;

  JadwalAmbil({
    required int id,
    required String jamMulai,
    required String jamSelesai,
    required bool isAktif,
  })  : _id = id,
        _jamMulai = jamMulai,
        _jamSelesai = jamSelesai,
        _isAktif = isAktif;

  int get id => _id;
  String get jamMulai => _jamMulai;
  String get jamSelesai => _jamSelesai;
  bool get isAktif => _isAktif;

  set isAktif(bool value) => _isAktif = value;

  void aturJadwal() {
    print('Mengatur jadwal $id: $_jamMulai - $_jamSelesai');
  }
}
