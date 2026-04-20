abstract class User {
  int _id;
  String _nama;
  String _email;
  String _password;
  String _role;

  User({
    required int id,
    required String nama,
    required String email,
    required String role,
    String password = '',
  })  : _id = id,
        _nama = nama,
        _email = email,
        _role = role,
        _password = password;

  // Encapsulation: Getters
  int get id => _id;
  String get nama => _nama;
  String get email => _email;
  String get role => _role;

  // Encapsulation: Setter for password
  set password(String value) => _password = value;

  // Abstraction & Polymorphism: Abstract methods
  bool login();
  void logout();

  // Common JSON conversion logic can be here or in subclasses
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _nama,
      'email': _email,
      'role': _role,
      'password': _password,
    };
  }
}
