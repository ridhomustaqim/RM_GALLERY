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

  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likeCount = 0;

  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  bool _isPageLoading = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _fetchBookmarkStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isPageLoading = true);
    try {
      await Future.wait([
        _fetchLikeStatus(),
        _fetchComments(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data awal: $e');
    } finally {
      setState(() => _isPageLoading = false);
    }
  }

  Future<void> _fetchLikeStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final userLikeResponse = await supabase
          .from('gallery_like')
          .select()
          .eq('id_image', widget.imageId)
          .eq('id_user', user.id);

      if (userLikeResponse is List) {
        setState(() => _isLiked = userLikeResponse.isNotEmpty);
      }

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

  Future<void> _fetchBookmarkStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('gallery_bookmarks')
          .select()
          .eq('id_user', user.id)
          .eq('id_image', widget.imageId);

      setState(() => _isBookmarked = response.isNotEmpty);
    } catch (e) {
      _showErrorSnackBar('Gagal memuat status bookmark: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Harap login untuk memberikan like');
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      if (_isLiked) {
        await supabase
            .from('gallery_like')
            .delete()
            .eq('id_user', user.id)
            .eq('id_image', widget.imageId);
      } else {
        await supabase.from('gallery_like').insert({
          'id_user': user.id,
          'id_image': widget.imageId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _fetchLikeStatus();
    } catch (e) {
      _showErrorSnackBar('Gagal mengubah status like: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Harap login untuk menyimpan gambar');
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      if (_isBookmarked) {
        await supabase
            .from('gallery_bookmarks')
            .delete()
            .eq('id_user', user.id)
            .eq('id_image', widget.imageId);
      } else {
        await supabase.from('gallery_bookmarks').insert({
          'id_user': user.id,
          'id_image': widget.imageId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _fetchBookmarkStatus();
    } catch (e) {
      _showErrorSnackBar('Gagal mengubah status bookmark: $e');
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

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
      appBar: AppBar(title: const Text("Detail Foto")),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Username",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "Deskripsi Foto",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: _toggleLike,
                          ),
                          Text('$_likeCount'),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _isBookmarked ? Colors.black : Colors.grey,
                        ),
                        onPressed: _toggleBookmark,
                      ),
                    ],
                  ),
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
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {},
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
