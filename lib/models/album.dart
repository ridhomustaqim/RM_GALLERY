class Album {
  final String id;
  final String nama;
  final String deskripsi;

  Album({required this.id, required this.nama, required this.deskripsi});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id_album'],
      nama: json['nama_album'],
      deskripsi: json['deskripsi_album'],
    );
  }
}
