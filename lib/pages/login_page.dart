import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Metode login menggunakan username (cari email di tabel `gallery_users`), 
  /// lalu panggil `signInWithPassword(email, password)` agar session Supabase terbentuk.
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final supabase = Supabase.instance.client;

      try {
        // 1. Cari email user berdasarkan username di tabel gallery_users
        final response = await supabase
            .from('gallery_users')
            .select('email') // hanya butuh email
            .eq('username', username)
            .maybeSingle();

        if (response == null) {
          _showSnackBar('Username tidak ditemukan');
          return;
        }

        final data = response as Map<String, dynamic>?;
        final email = data?['email'] as String?;
        if (email == null) {
          _showSnackBar('Data user tidak valid (email tidak ada)');
          return;
        }

        // 2. Login ke Supabase Auth (membuat session)
        final authResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        // 3. Jika session berhasil dibuat, user dianggap login
        if (authResponse.session != null) {
          _showSnackBar('Login berhasil!');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showSnackBar('Login gagal. Periksa email/password.');
        }
      } catch (e, stacktrace) {
        debugPrint('Error: $e');
        debugPrint('Stacktrace: $stacktrace');
        _showSnackBar('Terjadi kesalahan saat login');
      }
    } else {
      _showSnackBar('Periksa kembali form');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/RRR Logo.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                // ClipOval(
                //   child: Image.asset(
                //     'assets/images/RRR Logo.png',
                //     height: 120,
                //     width: 120,
                //     fit: BoxFit.cover,
                //   ),
                // ),
                const SizedBox(height: 40),

                // Input username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Input password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Tombol login
                ElevatedButton(
                  onPressed: _login,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: const Center(child: Text('Login')),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol navigasi ke registrasi
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Belum punya akun? Registrasi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
