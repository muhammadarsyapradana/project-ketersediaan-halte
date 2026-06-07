import 'package:kondisi_halte/main.dart'; // WAJIB DITAMBAHKAN untuk memanggil themeNotifier
import 'package:kondisi_halte/screens/add_post_screen.dart';
import 'package:kondisi_halte/screens/sign_in_screen.dart';
import 'package:kondisi_halte/screens/favorite_screen.dart'; // MENGIMPORT LAYAR FAVORIT
import 'package:kondisi_halte/services/post_service.dart';
import 'package:kondisi_halte/widgets/post_list_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isUploadingProfilePic = false; // Indikator loading saat upload

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  String generateAvatarUrl(String? fullName) {
    final formattedName = fullName?.trim().replaceAll(' ', '+') ?? 'User';
    return 'https://ui-avatars.com/api/?name=$formattedName&color=FFFFFF&background=000000';
  }

  // --- LOGIKA UPLOAD FOTO PROFIL YANG ASLI (Support Web & Mobile) ---
  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _isUploadingProfilePic = true; // Nyalakan loading
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Pengguna tidak ditemukan.');

        // 1. Buat referensi lokasi di Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');

        // 2. Baca gambar sebagai format "Bytes" (Ini wajib agar jalan di Web & Android)
        final bytes = await image.readAsBytes();
        
        // 3. Upload menggunakan putData
        await storageRef.putData(bytes);

        // 4. Dapatkan URL gambar yang berhasil diupload dari Storage
        final downloadUrl = await storageRef.getDownloadURL();

        // 5. Update URL foto di profil FirebaseAuth
        await user.updatePhotoURL(downloadUrl);
        
        // Refresh data user
        await user.reload();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunggah foto: $e')),
          );
        }
      } finally {
        setState(() {
          _isUploadingProfilePic = false; // Matikan loading
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final List<Widget> pages = [
      _buildHomeTab(currentUserId),
      const FavoriteScreen(), // MEMANGGIL LAYAR FAVORIT DI SINI
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 
            ? "UrbanStop Monitor" 
            : _selectedIndex == 1 
                ? "Favorit" 
                : "Profil Saya"),
      ),
      body: pages[_selectedIndex],
      
      floatingActionButton: _selectedIndex == 0 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddPostScreen()),
              );
            },
            child: const Icon(Icons.add),
          )
        : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Tampilan Tab Home
  Widget _buildHomeTab(String? currentUserId) {
    return StreamBuilder(
      stream: PostService.getPostList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada laporan halte.\nTekan + untuk melapor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isOwner = currentUserId != null && post.userId == currentUserId;
              return PostListItem(post: post, isOwner: isOwner);
            },
          ),
        );
      },
    );
  }

  // Tampilan Tab Profile
  Widget _buildProfileTab() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(
                  user?.photoURL ?? generateAvatarUrl(user?.displayName),
                ),
              ),
              
              // Tombol Kamera
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  onPressed: _updateProfilePicture, // Memanggil fungsi upload
                ),
              ),
              
              // Animasi Loading menutupi foto jika sedang upload
              if (_isUploadingProfilePic)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            user?.displayName ?? 'Nama Pengguna',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            user?.email ?? 'email@domain.com',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          
          const SizedBox(height: 24.0), // Jarak antara email dan switch
          
          // --- TOMBOL SWITCH DARK MODE ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier, // Mendengarkan perubahan tema dari main.dart
              builder: (_, mode, __) {
                return SwitchListTile(
                  title: const Text('Mode Gelap'),
                  secondary: Icon(
                    mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  ),
                  value: mode == ThemeMode.dark,
                  onChanged: (bool isDark) {
                    // Mengubah tema aplikasi secara realtime
                    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 24.0), // Jarak antara switch dan tombol Keluar

          ElevatedButton.icon(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar (Sign Out)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}