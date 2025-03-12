class GalleryUser {
  final String idUser;
  final String username;
  final String namaLengkap;
  final String email;
  final String password;
  final String alamat;
  final DateTime createdAt;

  GalleryUser({
    required this.idUser,
    required this.username,
    required this.namaLengkap,
    required this.email,
    required this.password,
    required this.alamat,
    required this.createdAt,
  });

  factory GalleryUser.fromJson(Map<String, dynamic> json) {
    return GalleryUser(
      idUser: json['id_user'] as String,
      username: json['username'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      alamat: json['alamat'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'username': username,
      'nama_lengkap': namaLengkap,
      'email': email,
      'password': password,
      'alamat': alamat,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
