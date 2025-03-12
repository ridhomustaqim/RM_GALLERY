import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  /// Melakukan pencarian berdasarkan keyword di kolom nama_foto dan keterangan_foto
  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final response = await supabase
          .from('gallery_image')
          .select('id_image, image_url, nama_foto, keterangan_foto, created_at')
          .or('nama_foto.ilike.%$keyword%,keterangan_foto.ilike.%$keyword%');

      if (response is List) {
        setState(() {
          searchResults = response.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      debugPrint('Error during search: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Field pencarian
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari foto...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _performSearch(_searchController.text.trim());
                  },
                ),
              ),
              onSubmitted: (value) {
                _performSearch(value.trim());
              },
            ),
            const SizedBox(height: 16),
            // Hasil pencarian
            isLoading
                ? const CircularProgressIndicator()
                : searchResults.isEmpty
                    ? const Text('Tidak ada hasil ditemukan')
                    : Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final result = searchResults[index];
                            return GestureDetector(
                              onTap: () {
                                // Navigasi ke halaman detail foto
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhotoDetailPage(
                                      imageId: result['id_image'],
                                      imageUrl: result['image_url'],
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
                                  result['image_url'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) {
                                    return const Center(child: Text('Gagal memuat gambar'));
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
