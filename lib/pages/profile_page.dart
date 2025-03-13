import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_page.dart';
import 'album_detail_page.dart';
import 'photo_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Key untuk mengakses state \_AlbumTab
  final GlobalKey<_AlbumTabState> _albumTabKey = GlobalKey<_AlbumTabState>();

  String? _userName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchUserName();
  }

  /// Mengambil username dari tabel `gallery_users`
  Future<void> _fetchUserName() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('gallery_users')
          .select('username')
          .eq('id_user', user.id)
          .maybeSingle();

      if (response != null && response is Map) {
        setState(() {
          _userName = response['username'] as String?;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching username: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildUploadTab() => const _UploadTab();

  /// Pasang key di sini agar kita bisa memanggil fungsinya dari FAB
  Widget _buildAlbumTab() => _AlbumTab(key: _albumTabKey);

  Widget _buildSaveTab() => const _SaveTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bagian info user (photo profile + username)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName != null ? '@$_userName' : 'No Name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // TabBar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.grid_view)), // Upload Tab
              Tab(icon: Icon(Icons.photo_album)), // Album Tab
              Tab(icon: Icon(Icons.bookmark)), // Save Tab
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUploadTab(),
                _buildAlbumTab(),
                _buildSaveTab(),
              ],
            ),
          ),
        ],
      ),
      // FAB muncul hanya saat tab Album aktif (index == 1)
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                // Akses state \_AlbumTab via GlobalKey, panggil _showAddAlbumDialog
                _albumTabKey.currentState?._showAddAlbumDialog();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// Tab Upload: Menampilkan foto yang diupload oleh user
class _UploadTab extends StatefulWidget {
  const _UploadTab({Key? key}) : super(key: key);

  @override
  State<_UploadTab> createState() => __UploadTabState();
}

class __UploadTabState extends State<_UploadTab> with AutomaticKeepAliveClientMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _uploads = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchUserUploads();
  }

  Future<void> _fetchUserUploads() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await supabase
          .from('gallery_image')
          .select('id_image, image_url, nama_foto, created_at')
          .eq('id_user', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _uploads = response.map((photo) => {
          'id': photo['id_image'],
          'url': photo['image_url'],
          'name': photo['nama_foto'],
          'created_at': photo['created_at'],
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching uploads: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_uploads.isEmpty) return const Center(child: Text('Belum ada upload'));

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _uploads.length,
      itemBuilder: (context, index) {
        final photo = _uploads[index];
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              photo['url'],
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) {
                return const Center(child: Icon(Icons.error, color: Colors.red));
              },
            ),
          ),
        );
      },
    );
  }
}

/// Tab Album: menampilkan daftar album milik user + dialog tambah album
class _AlbumTab extends StatefulWidget {
  const _AlbumTab({Key? key}) : super(key: key);

  @override
  State<_AlbumTab> createState() => _AlbumTabState();
}

class _AlbumTabState extends State<_AlbumTab> with AutomaticKeepAliveClientMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;

  final TextEditingController _albumNameController = TextEditingController();
  final TextEditingController _albumDescController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  @override
  void dispose() {
    _albumNameController.dispose();
    _albumDescController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlbums() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final response = await supabase
          .from('gallery_album')
          .select()
          .eq('id_user', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _albums = response.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error fetching albums: $e');
    }
  }

  /// Menampilkan dialog tambah album
  void _showAddAlbumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _albumNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Album',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _albumDescController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Album',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _addAlbum();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  /// Menambahkan album baru ke tabel `gallery_album`
  Future<void> _addAlbum() async {
    final albumName = _albumNameController.text.trim();
    final albumDesc = _albumDescController.text.trim();

    if (albumName.isEmpty) {
      _showSnackBar('Nama album tidak boleh kosong');
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar('User belum login');
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
        setState(() {
          _albums.insert(0, response.first);
        });
        _albumNameController.clear();
        _albumDescController.clear();
        _showSnackBar('Album berhasil ditambahkan!');
      }
    } catch (e) {
      _showSnackBar('Gagal menambah album: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Belum ada album', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddAlbumDialog,
              child: const Text('Tambah Album Baru'),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        final albumId = album['id_album'].toString();
        final albumName = album['nama_album'] ?? 'Tanpa Nama';
        final albumDesc = album['deskripsi_album'] ?? '';
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlbumDetailPage(
                  albumId: albumId,
                  albumName: albumName,
                ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover album placeholder
                Expanded(
                  child: Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.photo_album, size: 40, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(albumName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(albumDesc, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tab Save: menampilkan foto yang disimpan oleh user
class _SaveTab extends StatefulWidget {
  const _SaveTab({Key? key}) : super(key: key);
  
  @override
  State<_SaveTab> createState() => _SaveTabState();
}

class _SaveTabState extends State<_SaveTab> with AutomaticKeepAliveClientMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _savedPhotos = [];
  bool _isLoading = true;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _fetchSavedPhotos();
  }
  
  Future<void> _fetchSavedPhotos() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final response = await supabase
          .from('gallery_save')
          .select('*, gallery_image(*)')
          .eq('id_user', user.id);

      if (response is List) {
        List<Map<String, dynamic>> images = [];
        for (final save in response) {
          if (save['gallery_image'] != null) {
            if (save['gallery_image'] is List && (save['gallery_image'] as List).isNotEmpty) {
              final photoData = save['gallery_image'][0] as Map<String, dynamic>;
              images.add({
                'id': photoData['id_image'],
                'url': photoData['image_url'],
                'name': photoData['nama_foto'],
                'created_at': photoData['created_at'],
              });
            } else if (save['gallery_image'] is Map) {
              final photoData = save['gallery_image'] as Map<String, dynamic>;
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
          _savedPhotos = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching saved photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_savedPhotos.isEmpty) return const Center(child: Text('Belum ada foto yang disimpan'));
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _savedPhotos.length,
      itemBuilder: (context, index) {
        final photo = _savedPhotos[index];
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              photo['url'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) {
                return const Center(child: Icon(Icons.error, color: Colors.red));
              },
            ),
          ),
        );
      },
    );
  }
}
