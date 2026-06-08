import 'dart:convert';
import 'dart:typed_data';
import 'package:kondisi_halte/main.dart'; 
import 'package:kondisi_halte/screens/add_post_screen.dart';
import 'package:kondisi_halte/screens/sign_in_screen.dart';
import 'package:kondisi_halte/screens/favorite_screen.dart';
import 'package:kondisi_halte/services/post_service.dart';
import 'package:kondisi_halte/widgets/post_list_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _profileImageBase64; 
  bool _isProfileLoading = true;
  bool _isUploadingProfilePic = false; 

  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final String? _userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _loadFirebaseProfileData();
  }

  Future<void> _loadFirebaseProfileData() async {
    if (_currentUserId == null) {
      setState(() => _isProfileLoading = false);
      return;
    }

    try {
      // Ambil string foto profil dari Realtime Database cabang users
      final DataSnapshot userSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(_currentUserId!)
          .get();

      setState(() {
        if (userSnapshot.exists && userSnapshot.value != null) {
          final Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
          _profileImageBase64 = userData['profileKey'];
        }
      });
    } catch (e) {
      debugPrint("Gagal memuat data profil: \$e");
    } finally {
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _pickAndSaveProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40, 
      maxWidth: 400,
      maxHeight: 400,
    );
    
    if (image == null) return;

    setState(() {
      _isUploadingProfilePic = true;
    });

    try {
      if (_currentUserId == null) throw Exception('User tidak terautentikasi.');

      final Uint8List imageBytes = await image.readAsBytes();
      final String base64String = base64Encode(imageBytes);

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(_currentUserId!)
          .update({'profileKey': base64String});

      setState(() {
        _profileImageBase64 = base64String;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses foto: \$e')),
        );
      }
    } finally {
      setState(() {
        _isUploadingProfilePic = false;
      });
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(_currentUserId),
      const FavoriteScreen(), 
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(String? currentUserId) {
    return StreamBuilder(
      stream: PostService.getPostList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \${snapshot.error}'));
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

  Widget _buildProfileTab() {
    if (_isProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    ImageProvider profileImageProvider;
    if (_profileImageBase64 != null && _profileImageBase64!.length > 100) {
      try {
        profileImageProvider = MemoryImage(base64Decode(_profileImageBase64!));
      } catch (e) {
        profileImageProvider = const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png');
      }
    } else {
      profileImageProvider = const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png');
    }

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
                backgroundImage: profileImageProvider,
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  onPressed: _pickAndSaveProfilePicture,
                ),
              ),
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
            _userEmail?.split('@').first ?? 'Nama Pengguna',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0), // Menyisakan jarak antara nama dan email
          Text(
            _userEmail ?? 'email@domain.com',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) {
                return SwitchListTile(
                  title: const Text('Mode Gelap'),
                  secondary: Icon(
                    mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  ),
                  value: mode == ThemeMode.dark,
                  onChanged: (bool isDark) {
                    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24.0),
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