import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rm_gallery/pages/splash_screen.dart';
import 'package:rm_gallery/pages/login_page.dart';
import 'package:rm_gallery/pages/registrasi_page.dart';
import 'package:rm_gallery/pages/home_page.dart';
import 'package:rm_gallery/pages/profile_page.dart';
import 'package:rm_gallery/pages/search_page.dart';
import 'package:rm_gallery/pages/upload_page.dart';
import 'package:rm_gallery/pages/like_page.dart';
import 'package:rm_gallery/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://smgsbvoyhczishecyoyp.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtZ3Nidm95aGN6aXNoZWN5b3lwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMzg3ODAsImV4cCI6MjA1NTYxNDc4MH0.5-xTaSqWwjSGozkuRJVfVl1ZWr2ZtejgB5JFmjb2CjQ';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RM Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/search': (context) => const SearchPage(),
        '/upload': (context) => const UploadPage(),
        '/like': (context) => const LikePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}