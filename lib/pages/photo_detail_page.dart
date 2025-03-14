import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoDetailPage extends StatefulWidget {
  final String imageId;
  final String imageUrl;

  const PhotoDetailPage({Key? key, required this.imageId, required this.imageUrl}) : super(key: key);

  @override
  _PhotoDetailPageState createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  final supabase = Supabase.instance.client;
  String _photoUrl = '';
  String _photoDescription = '';
  String _uploaderId = '';
  String _uploaderUsername = '';
  bool _isOwner = false;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  List<Map<String, dynamic>> _comments = [];
  final _commentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotoDetails();
  }

  Future<void> _fetchPhotoDetails() async {
    try {
      // Ambil detail foto dari tabel gallery_image
      final photoResponse = await supabase
          .from('gallery_image')
          .select('url_foto, keterangan_foto, id_user, gallery_users(username)')
          .eq('id_image', widget.imageId)
          .single();

      // Ambil status like pengguna saat ini
      final user = supabase.auth.currentUser;
      final likeResponse = user != null
          ? await supabase
              .from('gallery_likes')
              .select()
              .eq('id_image', widget.imageId)
              .eq('id_user', user.id)
              .maybeSingle()
          : null;

      // Ambil status save pengguna saat ini
      final saveResponse = user != null
          ? await supabase
              .from('gallery_saves')
              .select()
              .eq('id_image', widget.imageId)
              .eq('id_user', user.id)
              .maybeSingle()
          : null;

      // Ambil jumlah like
      final likeCountResponse = await supabase
          .from('gallery_likes')
          .select('id_like')
          .eq('id_image', widget.imageId);

      // Ambil komentar
      final commentsResponse = await supabase
          .from('gallery_comments')
          .select('comment_text, id_user, gallery_users(username)')
          .eq('id_image', widget.imageId);

      setState(() {
        _photoUrl = photoResponse['url_foto'];
        _photoDescription = photoResponse['keterangan_foto'] ?? '';
        _uploaderId = photoResponse['id_user'];
        _uploaderUsername = photoResponse['gallery_users']['username'];
        _isOwner = user != null && user.id == _uploaderId;
        _isLiked = likeResponse != null;
        _isSaved = saveResponse != null;
        _likeCount = likeCountResponse.length;
        _comments = List<Map<String, dynamic>>.from(commentsResponse);
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat detail foto: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Silakan login untuk menyukai foto');
      return;
    }

    try {
      if (_isLiked) {
        await supabase
            .from('gallery_likes')
            .delete()
            .eq('id_image', widget.imageId)
            .eq('id_user', user.id);
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        await supabase.from('gallery_likes').insert({
          'id_image': widget.imageId,
          'id_user': user.id,
        });
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengubah status like: $e');
    }
  }

  Future<void> _toggleSave() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Silakan login untuk menyimpan foto');
      return;
    }

    try {
      if (_isSaved) {
        await supabase
            .from('gallery_saves')
            .delete()
            .eq('id_image', widget.imageId)
            .eq('id_user', user.id);
        setState(() => _isSaved = false);
      } else {
        await supabase.from('gallery_saves').insert({
          'id_image': widget.imageId,
          'id_user': user.id,
        });
        setState(() => _isSaved = true);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengubah status save: $e');
    }
  }

  Future<void> _addComment() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Silakan login untuk berkomentar');
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      await supabase.from('gallery_comments').insert({
        'id_image': widget.imageId,
        'id_user': user.id,
        'comment_text': commentText,
      });
      _commentController.clear();
      await _fetchPhotoDetails(); // Refresh komentar
      _showSnackBar('Komentar berhasil ditambahkan');
    } catch (e) {
      _showErrorSnackBar('Gagal menambahkan komentar: $e');
    }
  }

  Future<void> _editPhotoDescription() async {
    final newDescription = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _photoDescription);
        return AlertDialog(
          title: const Text('Edit Deskripsi Foto'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final desc = controller.text.trim();
                if (desc.isEmpty) return;
                Navigator.of(context).pop(desc);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (newDescription != null) {
      try {
        await supabase
            .from('gallery_image')
            .update({'keterangan_foto': newDescription})
            .eq('id_image', widget.imageId);
        setState(() => _photoDescription = newDescription);
        _showSnackBar('Deskripsi berhasil diperbarui');
      } catch (e) {
        _showErrorSnackBar('Gagal memperbarui deskripsi: $e');
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus foto ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _deletePhoto();
    }
  }

  Future<void> _deletePhoto() async {
    try {
      await supabase
          .from('gallery_image')
          .delete()
          .eq('id_image', widget.imageId);
      Navigator.pop(context);
      _showSnackBar('Foto berhasil dihapus');
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus foto: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Foto'),
        actions: [
          if (_isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editPhotoDescription();
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Foto'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus Foto'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Image.network(_photoUrl, fit: BoxFit.cover, width: double.infinity),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Like dan Save
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : null,
                            ),
                            onPressed: _toggleLike,
                          ),
                          Text('$_likeCount'),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        onPressed: _toggleSave,
                      ),
                    ],
                  ),
                  // Username dan Deskripsi
                  Text(
                    _uploaderUsername,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_photoDescription),
                  const SizedBox(height: 16),
                  // Komentar
                  const Text(
                    'Komentar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._comments.map((comment) => ListTile(
                        title: Text(comment['gallery_users']['username']),
                        subtitle: Text(comment['comment_text']),
                      )),
                  // Input Komentar
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Tambah komentar',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}