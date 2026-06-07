import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kondisi_halte/screens/home_screen.dart';
import 'package:kondisi_halte/screens/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32.0),
              
              // --- TAMBAHAN: Teks Welcome to UrbanStop Monitor ---
              const Text(
                'Welcome to\nUrbanStop Monitor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28, // Ukuran font diperbesar
                  fontWeight: FontWeight.bold, // Dibuat tebal (bold)
                  letterSpacing: 1.2, // Jarak antar huruf agar lebih rapi
                ),
              ),
              
              const SizedBox(height: 48.0), // Jarak antara teks dan kolom input
              
              // --- Kolom Input Email dengan Ikon ---
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email), // TAMBAHAN: Ikon Email
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              
              // --- Kolom Input Password dengan Ikon ---
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock), // TAMBAHAN: Ikon Password (Gembok)
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              
              // --- Tombol Sign In ---
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  } catch (error) {
                    setState(() {
                      _errorMessage = error.toString();
                    });
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(_errorMessage)));
                  }
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 32.0),
              
              // --- Tombol Pindah ke Halaman Sign Up ---
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}