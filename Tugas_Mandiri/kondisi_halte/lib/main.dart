import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kondisi_halte/screens/home_screen.dart';
import 'firebase_options.dart';
// Sesuaikan import home screen dan sign in screen Anda
import 'package:kondisi_halte/screens/sign_in_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

// --- VARIABEL GLOBAL UNTUK MENGENDALIKAN TEMA ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder akan membangun ulang MaterialApp 
    // secara otomatis setiap kali switch Dark Mode ditekan
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'UrbanStop Monitor',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode, // Mengikuti switch
          theme: ThemeData.light(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: const Color(0xFFF3F6F4), // Warna soft awal Anda
          ),
          darkTheme: ThemeData.dark(useMaterial3: true), // Tema Gelap Bawaan
          home: FirebaseAuth.instance.currentUser == null
              ? const SignInScreen()
              : const HomeScreen(), // Sesuaikan dengan navigasi awal Anda
        );
      },
    );
  }
}