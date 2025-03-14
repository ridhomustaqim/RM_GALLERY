import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoDetailPage extends StatefulWidget {
  final String imageId;
  final String imageUrl;

  const PhotoDetailPage({
    Key? key,
    required this.imageId,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  final supabase = Supabase.instance.client;

  // Status Like
  bool _isLiked = false;
  int _likeCount = 0;

  bool _isSaved = false;

  bool _isOwner = false;
  String _uploaderId = '';

  // Data uploader & deskripsi
  String _uploaderUsername = 'Loading...';
  String _photoDescription = 'Loading...';

  // Komentar
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  bool _isPageLoading = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Memuat data awal (like, save, detail foto, komentar)
  Future<void> _loadInitialData() async {
    setState(() => _isPageLoading = true);
    try {
      await Future.wait([
        _fetchLikeStatus(),
        _fetchSaveStatus(),
        _fetchPhotoDetails(),
        _fetchComments(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data awal: $e');
    } finally {
      setState(() => _isPageLoading = false);
    }
  }

  /// Ambil data username & deskripsi dari `gallery_image` + `gallery_users`
  Future<void> _fetchPhotoDetails() async {
    try {
      final response = await supabase
          .from('gallery_image')
          .select('id_user, keterangan_foto, gallery_users(username)')
          .eq('id_image', widget.imageId)
          .maybeSingle();

      if (response != null && response is Map) {
        final userMap = response['gallery_users'] as Map<String, dynamic>?;
        setState(() {
          _uploaderId = response['id_user']; // Simpan ID pemilik foto
          _uploaderUsername = userMap?['username'] ?? 'Unknown';
          _photoDescription = response['keterangan_foto'] ?? 'Tidak ada deskripsi.';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat detail foto: $e');
    }
  }


  /// Mengecek apakah user sudah like + menghitung total like
  Future<void> _fetchLikeStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return; // Skip jika belum login

    try {
      // 1. Cek apakah user sudah like
      final userLikeResponse = await supabase
          .from('gallery_like')
          .select()
          .eq('id_image', widget.imageId)
          .eq('id_user', user.id);

      if (userLikeResponse is List) {
        setState(() => _isLiked = userLikeResponse.isNotEmpty);
      }

      // 2. Ambil semua like di gambar ini, lalu hitung length
      final allLikesResponse = await supabase
          .from('gallery_like')
          .select()
          .eq('id_image', widget.imageId);

      if (allLikesResponse is List) {
        setState(() => _likeCount = allLikesResponse.length);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat status like: $e');
    }
  }

  /// Mengecek apakah user sudah save
  Future<void> _fetchSaveStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final userSaveResponse = await supabase
          .from('gallery_save')
          .select()
          .eq('id_image', widget.imageId)
          .eq('id_user', user.id);

      if (userSaveResponse is List) {
        setState(() => _isSaved = userSaveResponse.isNotEmpty);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat status save: $e');
    }
  }

  /// Toggle Like (jika belum like → insert, jika sudah like → delete)
  Future<void> _toggleLike() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Harap login terlebih dahulu untuk like');
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      if (_isLiked) {
        // Hapus like
        await supabase
            .from('gallery_like')
            .delete()
            .eq('id_user', user.id)
            .eq('id_image', widget.imageId);
      } else {
        // Tambah like
        await supabase.from('gallery_like').insert({
          'id_user': user.id,
          'id_image': widget.imageId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Refresh status like
      await _fetchLikeStatus();
    } catch (e) {
      _showErrorSnackBar('Gagal mengubah status like: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  /// Toggle Save (jika belum save → insert, jika sudah save → delete)
  Future<void> _toggleSave() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Harap login terlebih dahulu untuk menyimpan');
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      if (_isSaved) {
        // Hapus save
        await supabase
            .from('gallery_save')
            .delete()
            .eq('id_user', user.id)
            .eq('id_image', widget.imageId);
      } else {
        // Tambah save
        await supabase.from('gallery_save').insert({
          'id_user': user.id,
          'id_image': widget.imageId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Refresh status save
      await _fetchSaveStatus();
    } catch (e) {
      _showErrorSnackBar('Gagal mengubah status save: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  /// Ambil daftar komentar
  Future<void> _fetchComments() async {
    try {
      final response = await supabase
          .from('gallery_komentar')
          .select('*, gallery_users(username)')
          .eq('id_image', widget.imageId)
          .order('created_at', ascending: false);

      if (response is List) {
        setState(() {
          _comments = response.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat komentar: $e');
    }
  }

  /// Tambah komentar
  Future<void> _addComment() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Harap login terlebih dahulu untuk berkomentar');
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() => _isActionLoading = true);
    try {
      await supabase.from('gallery_komentar').insert({
        'id_user': user.id,
        'id_image': widget.imageId,
        'isi_komentar': commentText,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Bersihkan field komentar
      _commentController.clear();
      FocusScope.of(context).unfocus();

      // Refresh komentar
      await _fetchComments();
    } catch (e) {
      _showErrorSnackBar('Gagal menambah komentar: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  /// Tampilkan Snackbar error
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Foto"),
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Gambar utama
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (ctx, err, stack) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Gagal memuat gambar"),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Row: Like & Save (kiri), Menu (kanan)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Like
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.grey,
                          ),
                          onPressed: _toggleLike,
                        ),
                        Text('$_likeCount Likes'),
                        // Save
                        IconButton(
                          icon: Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: _isSaved ? Colors.black : Colors.grey,
                          ),
                          onPressed: _toggleSave,
                        ),
                        const SizedBox(width: 8),

                        const Spacer(),
                        // Icon Menu di kanan
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // Fitur menu (placeholder)
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Username & Deskripsi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username yang upload
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _uploaderUsername, 
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Deskripsi foto
                        Row(
                          children: [
                            const Icon(Icons.description, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(_photoDescription),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Form Komentar
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Tulis komentar...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isActionLoading
                            ? const CircularProgressIndicator()
                            : IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: _addComment,
                              ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Daftar Komentar
                  _comments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Belum ada komentar'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final komentar = _comments[index];
                            final userName = komentar['gallery_users']?['username'] ?? 'Unknown';
                            final isi = komentar['isi_komentar'] ?? '';
                            final createdAt = komentar['created_at'] ?? '';

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(
                                userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isi),
                                  const SizedBox(height: 4),
                                  Text(
                                    createdAt,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
