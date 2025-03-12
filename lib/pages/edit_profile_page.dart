import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  /// Mengambil data user (username, alamat) dari tabel `gallery_users`
  Future<void> _fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar('User belum login');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Hanya select kolom username & alamat
      final response = await supabase
          .from('gallery_users')
          .select('username, alamat')
          .eq('id_user', user.id)
          .maybeSingle();

      if (response != null && response is Map) {
        _usernameController.text = response['username'] ?? '';
        _alamatController.text = response['alamat'] ?? '';
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil profil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Menyimpan perubahan ke tabel `gallery_users` (hanya username dan alamat)
  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar('User belum login');
      return;
    }

    final newUsername = _usernameController.text.trim();
    final newAlamat = _alamatController.text.trim();

    // Validasi field yang wajib
    if (newUsername.isEmpty) {
      _showSnackBar('Mohon isi username');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update di tabel `gallery_users`
      await supabase
          .from('gallery_users')
          .update({
            'username': newUsername,
            'alamat': newAlamat,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', user.id);

      _showSnackBar('Profil berhasil diperbarui!');
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } catch (e) {
      _showSnackBar('Gagal memperbarui profil: $e');
    } finally {
      setState(() => _isLoading = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Input Username
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Alamat
                  TextField(
                    controller: _alamatController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2, // bisa 2 baris jika alamat panjang
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
    );
  }
}
