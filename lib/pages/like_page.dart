import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo_detail_page.dart';

class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> likedImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedImages();
  }

  Future<void> _fetchLikedImages() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Query: ambil data like milik user dan join dengan gallery_image
      final response = await supabase
          .from('gallery_like')
          .select('*, gallery_image(*)')
          .eq('id_user', user.id);

      if (response is List) {
        List<Map<String, dynamic>> images = [];
        for (final like in response) {
          if (like['gallery_image'] != null) {
            if (like['gallery_image'] is List && (like['gallery_image'] as List).isNotEmpty) {
              final photoData = like['gallery_image'][0] as Map<String, dynamic>;
              images.add({
                'id': photoData['id_image'],
                'url': photoData['image_url'],
                'name': photoData['nama_foto'],
                'created_at': photoData['created_at'],
              });
            } else if (like['gallery_image'] is Map) {
              final photoData = like['gallery_image'] as Map<String, dynamic>;
              images.add({
                'id': photoData['id_image'],
                'url': photoData['image_url'],
                'name': photoData['nama_foto'],
                'created_at': photoData['created_at'],
              });
            }
          }
        }
        setState(() {
          likedImages = images;
        });
      }
    } catch (e) {
      debugPrint('Error fetching liked images: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Posts'),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : likedImages.isEmpty
              ? const Center(child: Text('Tidak ada postingan yang disukai'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 8, 
                    mainAxisSpacing: 8,
                  ),
                  itemCount: likedImages.length,
                  itemBuilder: (context, index) {
                    final photo = likedImages[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigasi ke halaman detail foto
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
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          photo['url'] ?? '',
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
