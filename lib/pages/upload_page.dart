import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ImagePicker _picker = ImagePicker();

  /// Controllers untuk deskripsi foto & nama/desc album
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _albumNameController = TextEditingController();
  final TextEditingController _albumDescController = TextEditingController();

  final supabase = Supabase.instance.client;

  File? _mobileFile;
  Uint8List? _webFileBytes; // Untuk Web

  List<Map<String, dynamic>> _albums = [];
  String? _selectedAlbum;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  @override
  void dispose() {
    _descController.dispose();
    _albumNameController.dispose();
    _albumDescController.dispose();
    super.dispose();
  }

  /// Mengambil album milik user login
  Future<void> _fetchAlbums() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('User belum login');
      return;
    }
    try {
      final response = await supabase
          .from('gallery_album')
          .select()
          .eq('id_user', user.id)
          .order('created_at', ascending: false);

      if (response is List) {
        setState(() {
          _albums = response.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil album: $e');
    }
  }

  /// Menampilkan dialog untuk menambah album (Nama & Deskripsi)
  void _showAddAlbumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Album"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _albumNameController,
              decoration: const InputDecoration(
                labelText: "Nama Album",
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _albumDescController,
              decoration: const InputDecoration(
                labelText: "Deskripsi Album",
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _addAlbum();
              Navigator.pop(ctx);
            },
            child: const Text("Tambah"),
          ),
        ],
      ),
    );
  }

  /// Menambah album baru ke tabel `gallery_album`
  Future<void> _addAlbum() async {
    final albumName = _albumNameController.text.trim();
    final albumDesc = _albumDescController.text.trim();
    if (albumName.isEmpty) {
      _showErrorSnackBar('Nama album tidak boleh kosong');
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('User belum login');
      return;
    }

    try {
      final response = await supabase
          .from('gallery_album')
          .insert({
            'nama_album': albumName,
            'deskripsi_album': albumDesc,
            'id_user': user.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select();

      if (response is List && response.isNotEmpty) {
        final newAlbum = response.first as Map<String, dynamic>;
        setState(() {
          // Masukkan album baru ke list & set album terpilih
          _albums.insert(0, newAlbum);
          _selectedAlbum = newAlbum['id_album'].toString();
        });
        _albumNameController.clear();
        _albumDescController.clear();
        _showSuccessSnackBar('Album berhasil ditambahkan!');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal menambahkan album: $e');
    }
  }

  /// Memilih gambar dari galeri
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webFileBytes = bytes;
            _mobileFile = null;
          });
        } else {
          setState(() {
            _mobileFile = File(pickedFile.path);
            _webFileBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  /// Unggah gambar ke Supabase Storage & simpan metadata ke `gallery_image`
  Future<void> _uploadImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('User belum login');
      return;
    }

    if ((!kIsWeb && _mobileFile == null) || (kIsWeb && _webFileBytes == null)) {
      _showErrorSnackBar('Silakan pilih gambar terlebih dahulu');
      return;
    }
    if (_selectedAlbum == null || _selectedAlbum!.isEmpty) {
      _showErrorSnackBar('Pilih album terlebih dahulu');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Buat nama file unik
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'gallery/$fileName';

      // Upload
      if (kIsWeb) {
        await supabase.storage.from('rm_gallery').uploadBinary(
          storagePath,
          _webFileBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      } else {
        await supabase.storage.from('rm_gallery').upload(
          storagePath,
          _mobileFile!,
          fileOptions: const FileOptions(upsert: true),
        );
      }

      // Dapatkan URL publik
      final publicUrl = supabase.storage.from('rm_gallery').getPublicUrl(storagePath);

      // Insert metadata ke tabel `gallery_image`
      await supabase.from('gallery_image').insert({
        'id_album': _selectedAlbum,
        'id_user': user.id,
        'nama_foto': p.basename(fileName),
        'keterangan_foto': _descController.text.trim(),
        'image_url': publicUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      _showSuccessSnackBar('Gambar berhasil diunggah!');

      // Reset form
      setState(() {
        _mobileFile = null;
        _webFileBytes = null;
        _selectedAlbum = null;
        _descController.clear();
      });
    } catch (e) {
      _showErrorSnackBar('Gagal mengunggah gambar: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Snackbar sukses
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Snackbar error
  void _showErrorSnackBar(String message, [Object? error]) {
    if (!mounted) return;
    final fullMessage = error == null ? message : '$message: $error';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fullMessage), backgroundColor: Colors.red),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      if (_webFileBytes == null) {
        return const Text(
          "Belum ada gambar yang dipilih",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        );
      }
      return Image.memory(_webFileBytes!, height: 200, fit: BoxFit.cover);
    } else {
      if (_mobileFile == null) {
        return const Text(
          "Belum ada gambar yang dipilih",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        );
      }
      return Image.file(_mobileFile!, height: 200, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unggah Gambar")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview Gambar
            _buildImagePreview(),
            const SizedBox(height: 16),

            // Tombol Pilih Gambar
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Pilih Gambar"),
            ),
            const SizedBox(height: 16),

            // Input Keterangan Foto
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Keterangan Foto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Album
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAlbum,
                    onChanged: (val) => setState(() => _selectedAlbum = val),
                    items: _albums.map((album) {
                      final idAlbum = album['id_album'].toString();
                      final namaAlbum = album['nama_album'] ?? 'Tanpa Nama';
                      return DropdownMenuItem(value: idAlbum, child: Text(namaAlbum));
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Pilih Album',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Pilih Album"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddAlbumDialog,
                  tooltip: "Tambah Album Baru",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Unggah
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadImage,
              icon: _isUploading ? const SizedBox.shrink() : const Icon(Icons.cloud_upload),
              label: _isUploading
                ? const CircularProgressIndicator()
                : const Text("Unggah"),
            ),
          ],
        ),
      ),
    );
  }
}
