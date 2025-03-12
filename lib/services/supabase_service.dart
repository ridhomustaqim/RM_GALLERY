import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rm_gallery/utils/constants.dart';
import 'package:path/path.dart' as p;

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Membuat akun dengan Supabase Auth dan menyimpan data tambahan ke tabel `gallery_users`
  Future<AuthResponse> signUp({
    required String username,
    required String namaLengkap,
    required String email,
    required String password,
  }) async {
    try {
      // Buat akun di Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        final userId = authResponse.user!.id;
        final hashedPassword = sha256.convert(utf8.encode(password)).toString();
        
        // Insert data ke tabel gallery_users
        await _supabase.from('gallery_users').insert({
          'id_user': userId,
          'username': username,
          'nama_lengkap': namaLengkap,
          'email': email,
          'password': hashedPassword,
          'created_at': DateTime.now().toIso8601String(),
        }).select().single();
      }
      return authResponse;
    } on PostgrestException catch (e) {
      throw Exception('Kesalahan database: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('Kesalahan autentikasi: ${e.message}');
    } catch (e) {
      throw Exception('Kesalahan tidak terduga: $e');
    }
  }

  /// Autentikasi user dengan email dan password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login gagal');
      }
      return response;
    } on AuthException catch (e) {
      throw Exception('Login gagal: ${e.message}');
    }
  }

  /// Keluar (sign out) dari session
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Mengambil daftar album berdasarkan user yang sedang login
  Future<List<Map<String, dynamic>>> getAlbums() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login');
    
    try {
      final response = await _supabase
          .from('gallery_album')
          .select()
          .eq('id_user', user.id)
          .order('created_at', ascending: false);

      if (response is List && response.isEmpty) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mengambil album: $e');
    }
  }

  /// Mengunggah file gambar ke Supabase Storage dan menyimpan metadata ke tabel `gallery_image`
  Future<String> uploadImage({
    required File file,
    required String albumId,
    String? namaFoto,
    String? keteranganFoto,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login');
    
    try {
      // Generate nama file unik
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      
      // Upload file ke bucket 'rm_gallery'
      await _supabase.storage.from('rm_gallery').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      
      // Dapatkan URL publik
      final publicUrl = _supabase.storage.from('rm_gallery').getPublicUrl(fileName);
      
      // Simpan metadata gambar ke tabel `gallery_image`
      await _supabase.from('gallery_image').insert({
        'id_album': albumId,
        'id_user': user.id,
        'nama_foto': namaFoto ?? p.basename(file.path),
        'keterangan_foto': keteranganFoto ?? '',
        'image_url': publicUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Upload error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Mendapatkan profil pengguna dari tabel `gallery_users`
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login');
    
    try {
      final response = await _supabase
          .from('gallery_users')
          .select()
          .eq('id_user', user.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
    }
  }

  /// Memperbarui profil pengguna
  Future<void> updateUserProfile({
    String? username,
    String? namaLengkap,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login');
    
    try {
      await _supabase
          .from('gallery_users')
          .update({
            if (username != null) 'username': username,
            if (namaLengkap != null) 'nama_lengkap': namaLengkap,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_user', user.id);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }
}
