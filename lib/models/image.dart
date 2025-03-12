class ImageModel {
  final String id;
  final String nama;
  final String url;

  ImageModel({required this.id, required this.nama, required this.url});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id_image'],
      nama: json['nama_foto'],
      url: json['image_url'],
    );
  }
}
