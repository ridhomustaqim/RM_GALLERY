import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'like_page.dart';
import 'search_page.dart';
import 'upload_page.dart';
import 'photo_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _photoList = [];

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  /// Mengambil foto dari Supabase
  Future<void> _fetchPhotos() async {
    setState(() {
      _isLoading = true; // Menampilkan loading sebelum data diperbarui
    });

    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('gallery_image')
          .select('id_image, image_url, nama_foto, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      if (response is List && response.isNotEmpty) {
        setState(() {
          _photoList = response.map<Map<String, dynamic>>((photo) {
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
      debugPrint('Error fetching photos: $e');
    } finally {
      setState(() {
        _isLoading = false; // Menghilangkan loading setelah data diambil
      });
    }
  }

  /// Menampilkan Bottom Sheet saat tombol tambah ditekan
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          widthFactor: 1,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Mulai berkreasi sekarang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Unggah foto baru',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UploadPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.image, color: Colors.purple),
                    label: const Text("Pilih foto"),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? _buildHomeContent()
          : _selectedIndex == 1
              ? const SearchPage()
              : _selectedIndex == 3
                  ? const LikePage()
                  : _selectedIndex == 4
                      ? const ProfilePage()
                      : _buildHomeContent(),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        items: const [
          Icon(Icons.home, size: 30),
          Icon(Icons.search, size: 30),
          Icon(Icons.add_box_outlined, size: 30),
          Icon(Icons.favorite, size: 30),
          Icon(Icons.person, size: 30),
        ],
        onTap: (index) {
          if (index == 0) {
            if (_selectedIndex == 0) {
              _fetchPhotos(); // Refresh data jika sedang di halaman Home
            }
          } else if (index == 2) {
            _showAddOptions();
            return; // Mencegah perubahan state karena _showAddOptions sudah menangani aksi
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        height: 60.0,
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        backgroundColor: Colors.transparent,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Tampilan utama Home (hanya foto)
  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchPhotos,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              automaticallyImplyLeading: false,
              leading: Container(
                margin: const EdgeInsets.only(left: 16),
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/RRR Logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()))
                  : _photoList.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(child: Text('Tidak ada foto tersedia')))
                      : SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final photo = _photoList[index];
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
                                      return const Center(
                                          child: Text('Gagal memuat gambar'));
                                    },
                                  ),
                                ),
                              );
                            },
                            childCount: _photoList.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
