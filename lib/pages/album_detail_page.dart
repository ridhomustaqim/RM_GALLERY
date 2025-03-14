import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo_detail_page.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const AlbumDetailPage({
    Key? key,
    required this.albumId,
    required this.albumName,
  }) : super(key: key);

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlbumPhotos();
  }

  Future<void> _fetchAlbumPhotos() async {
    try {
      final response = await supabase
          .from('gallery_image')
          .select('id_image, image_url, nama_foto, created_at')
          .eq('id_album', widget.albumId)
          .order('created_at', ascending: false);
      if (response is List) {
        setState(() {
          _photos = response.map((photo) {
            return {
              'id': photo['id_image'],
              'url': photo['image_url'],
              'name': photo['nama_foto'],
              'created_at': photo['created_at'],
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching album photos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus semua foto dalam album ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllPhotos();
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete all photos in this album
      await supabase
        .from('gallery_album')
        .delete()
        .eq('id_album', widget.albumId);
      
      // Refresh the photos list
      _photos = [];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua album dan foto berhasil dihapus')),
      );
    } catch (e) {
      debugPrint('Error deleting photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus foto')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEditAlbum() {
    // Navigate to edit album page - implement this as needed
    // For example:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => EditAlbumPage(
    //       albumId: widget.albumId,
    //       albumName: widget.albumName,
    //     ),
    //   ),
    // ).then((_) {
    //   // Refresh data when coming back from edit page
    //   _fetchAlbumPhotos();
    // });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur edit album akan segera tersedia')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEditAlbum();
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit Album'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Semua Foto'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(child: Text('Belum ada foto dalam album ini'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoDetailPage(
                              imageId: photo['id'],
                              imageUrl: photo['url'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          photo['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) {
                            return const Center(child: Text('Gagal memuat gambar'));
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}