import 'package:flutter/material.dart';
import 'package:kondisi_halte/models/post.dart';
import 'package:kondisi_halte/widgets/post_list_item.dart';

class FavoriteScreen extends StatefulWidget {
  // Variabel statis ini menggantikan globals.dart
  // Bisa diakses dari mana saja dengan memanggil FavoriteScreen.favoritePosts
  static List<Post> favoritePosts = [];

  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FavoriteScreen.favoritePosts.isEmpty
          ? const Center(
              child: Text(
                'Daftar Halte Favorit Anda Masih Kosong',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: FavoriteScreen.favoritePosts.length,
              itemBuilder: (context, index) {
                final post = FavoriteScreen.favoritePosts[index];
                return PostListItem(
                  post: post,
                  isOwner: false, // Disembunyikan fitur edit/hapusnya di layar ini
                );
              },
            ),
    );
  }
}