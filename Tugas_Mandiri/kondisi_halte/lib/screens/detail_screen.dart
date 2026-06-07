import 'dart:convert';
import 'package:kondisi_halte/models/post.dart';
import 'package:kondisi_halte/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DetailScreen extends StatefulWidget {
  final Post post;
  final bool initialFavorite; // Menerima status favorit dari halaman depan

  const DetailScreen({
    super.key, 
    required this.post, 
    required this.initialFavorite,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.initialFavorite; // Set status awal saat halaman dibuka
  }

  Future<void> _deletePost(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE3F2FD),
        title: const Text('Hapus Laporan'),
        content: const Text('Apakah Anda yakin ingin menghapus data laporan kondisi halte ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PostService.deletePost(widget.post);
      if (context.mounted) {
        // Kembali ke halaman sebelumnya dan kirim status favorit terbaru
        Navigator.pop(context, isFavorite); 
      }
    }
  }

  void _sharePost() {
    final text =
        'Kondisi Halte: ${widget.post.category ?? ''}\nDetail: ${widget.post.description ?? ''}\nDilaporkan oleh: ${widget.post.userFullName ?? ''}\n\nVia UrbanStop Monitor';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && widget.post.userId == currentUserId;
    
    // Cek apakah mode gelap sedang aktif
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Warna background akan otomatis berubah sesuai Theme (hapus warna permanen)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparan agar menyatu dengan background
        // Override tombol back agar mengirimkan status isFavorite saat kembali
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, isFavorite),
        ),
        title: Text(
          widget.post.category ?? 'Detail Laporan',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // IKON FAVORITE DI DETAIL SCREEN
          IconButton(
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.pink : (isDark ? Colors.white70 : Colors.grey),
            ),
            tooltip: 'Favorit',
          ),
          IconButton(
            onPressed: _sharePost,
            icon: const Icon(Icons.share),
            tooltip: 'Bagikan Laporan',
          ),
          if (isOwner)
            IconButton(
              onPressed: () => _deletePost(context),
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Hapus Laporan',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.image != null && widget.post.image!.isNotEmpty)
              Image.memory(
                base64Decode(widget.post.image!),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: isDark ? Colors.grey[800] : const Color(0xFFFFF9C4),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.category != null)
                    Chip(
                      label: Text(widget.post.category!),
                      backgroundColor: isDark ? Colors.green[900] : const Color(0xFFE8F5E9),
                      side: BorderSide.none,
                    ),
                  const SizedBox(height: 12),
                  
                  // Container Deskripsi yang adaptif terhadap Dark Mode
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.grey[800] 
                          : const Color(0xFFE1BEE7).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.post.description ?? 'Tidak ada deskripsi kerusakan.',
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        widget.post.userFullName ?? 'Anonim',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (widget.post.latitude != null && widget.post.longitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Koordinat: ${widget.post.latitude}, ${widget.post.longitude}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}