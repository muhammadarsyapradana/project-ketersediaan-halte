import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kondisi_halte/models/post.dart';
import 'package:kondisi_halte/screens/detail_screen.dart';
import 'package:kondisi_halte/services/post_service.dart';
import 'package:kondisi_halte/screens/favorite_screen.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class PostListItem extends StatefulWidget {
  final Post post;
  final bool isOwner;

  const PostListItem({super.key, required this.post, required this.isOwner});

  @override
  State<PostListItem> createState() => _PostListItemState();
}

class _PostListItemState extends State<PostListItem> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void didUpdateWidget(PostListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkIfFavorite();
  }

  void _checkIfFavorite() {
    isFavorite = FavoriteScreen.favoritePosts.any((fav) => 
        (fav.id != null && fav.id == widget.post.id) || 
        (fav.description == widget.post.description));
  }

  void _toggleFavoriteList(bool status) {
    if (status) {
      if (!FavoriteScreen.favoritePosts.any((fav) => 
          (fav.id != null && fav.id == widget.post.id) || 
          (fav.description == widget.post.description))) {
        FavoriteScreen.favoritePosts.add(widget.post);
      }
    } else {
      FavoriteScreen.favoritePosts.removeWhere((fav) => 
          (fav.id != null && fav.id == widget.post.id) || 
          (fav.description == widget.post.description));
    }
  }

  // FUNGSI BARU: Membuka koordinat ke Google Maps
  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi tidak tersedia atau belum disetel')),
      );
      return;
    }
    
    // Format URL pencarian lokasi di Google Maps
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi Google Maps')),
        );
      }
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PostService.deletePost(widget.post);
      setState(() {
        _toggleFavoriteList(false);
      });
    }
  }

  Future<void> _editPostPopUp(BuildContext context) async {
    final TextEditingController descController = TextEditingController(text: widget.post.description);
    String? selectedCategory = widget.post.category;
    String? newBase64Image = widget.post.image;

    double? newLatitude = widget.post.latitude != null ? double.tryParse(widget.post.latitude.toString()) : null;
    double? newLongitude = widget.post.longitude != null ? double.tryParse(widget.post.longitude.toString()) : null;
    
    bool isGettingLocation = false;
    String? oldDescription = widget.post.description;

    final List<String> categories = [
      'Atap atau Kursi Rusak', 
      'Lampu Halte Mati', 
      'Kotor dan Penuh Sampah', 
      'Papan Informasi Rusak', 
      'Halte Beralih Fungsi',
      'Tidak Ada Halte'
    ];
    
    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Laporan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: newBase64Image != null && newBase64Image!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(base64Decode(newBase64Image!), fit: BoxFit.cover),
                            )
                          : const Center(child: Text('Tidak ada foto')),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setStateDialog(() {
                            newBase64Image = base64Encode(bytes);
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Ganti Foto'),
                    ),
                    const Divider(height: 24),
                    
                    // BAGIAN LOKASI YANG BISA DIKLIK UNTUK CEK MAPS
                    InkWell(
                      onTap: () => _openMap(newLatitude, newLongitude),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            // Diubah ukurannya agar lebih menonjol seperti pin peta
                            const Icon(Icons.location_on, color: Colors.red, size: 32),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    newLatitude != null && newLongitude != null
                                        ? 'Lat: ${newLatitude!.toStringAsFixed(4)}, Lng: ${newLongitude!.toStringAsFixed(4)}'
                                        : 'Lokasi belum disetel',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  if (newLatitude != null)
                                    const Text('Klik untuk melihat di Maps', style: TextStyle(fontSize: 10, color: Colors.blue)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: isGettingLocation
                          ? null
                          : () async {
                              setStateDialog(() => isGettingLocation = true);
                              try {
                                bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                if (!serviceEnabled) throw Exception('GPS tidak aktif');

                                LocationPermission permission = await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission = await Geolocator.requestPermission();
                                  if (permission == LocationPermission.denied) throw Exception('Izin ditolak');
                                }

                                Position position = await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.high);
                                
                                setStateDialog(() {
                                  newLatitude = position.latitude;
                                  newLongitude = position.longitude;
                                });
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal lokasi: $e')));
                                }
                              } finally {
                                setStateDialog(() => isGettingLocation = false);
                              }
                            },
                      icon: isGettingLocation
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      label: Text(isGettingLocation ? 'Mencari...' : 'Perbarui Lokasi GPS'),
                    ),
                    const Divider(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedCategory = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.post.id)
                          .update({
                        'category': selectedCategory,
                        'description': descController.text.trim(),
                        'image': newBase64Image,
                        'latitude': newLatitude?.toString(),
                        'longitude': newLongitude?.toString(),
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        
                        setState(() {
                          widget.post.category = selectedCategory;
                          widget.post.description = descController.text.trim();
                          widget.post.image = newBase64Image;
                          widget.post.latitude = newLatitude?.toString();
                          widget.post.longitude = newLongitude?.toString();

                          int favIndex = FavoriteScreen.favoritePosts.indexWhere((fav) => 
                              (fav.id != null && fav.id == widget.post.id) || 
                              (fav.description == oldDescription)
                          );
                          
                          if (favIndex != -1) {
                            FavoriteScreen.favoritePosts[favIndex].category = selectedCategory;
                            FavoriteScreen.favoritePosts[favIndex].description = descController.text.trim();
                            FavoriteScreen.favoritePosts[favIndex].image = newBase64Image;
                            FavoriteScreen.favoritePosts[favIndex].latitude = newLatitude?.toString();
                            FavoriteScreen.favoritePosts[favIndex].longitude = newLongitude?.toString();
                          }
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Laporan berhasil diedit & Favorit otomatis diperbarui!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengedit: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sharePost() {
    final text = 'Kondisi Halte: ${widget.post.category ?? ''}\nDetail: ${widget.post.description ?? ''}\nDilaporkan oleh: ${widget.post.userFullName ?? ''}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    // Parsing manual untuk icon Map di list
    double? listLatitude = widget.post.latitude != null ? double.tryParse(widget.post.latitude.toString()) : null;
    double? listLongitude = widget.post.longitude != null ? double.tryParse(widget.post.longitude.toString()) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () async {
          final updatedFavorite = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => DetailScreen(post: widget.post, initialFavorite: isFavorite),
            ),
          );

          if (updatedFavorite != null && updatedFavorite != isFavorite) {
            setState(() {
              isFavorite = updatedFavorite;
              _toggleFavoriteList(isFavorite);
            });
          }
        },
        leading: widget.post.image != null && widget.post.image!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  base64Decode(widget.post.image!), width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 56),
                ),
              )
            : const Icon(Icons.article, size: 56),
        title: Text(widget.post.category ?? 'Tanpa Kategori', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.post.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(widget.post.userFullName ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TOMBOL BARU UNTUK BUKA MAPS LANGSUNG DARI LIST (Icon Pin Merah Google Maps)
            IconButton(
              onPressed: () => _openMap(listLatitude, listLongitude),
              icon: const Icon(Icons.location_on, color: Colors.red, size: 28),
              padding: const EdgeInsets.symmetric(horizontal: 4), constraints: const BoxConstraints(),
            ),

            IconButton(
              onPressed: () {
                setState(() {
                  isFavorite = !isFavorite;
                  _toggleFavoriteList(isFavorite);
                });
              },
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.pink : Colors.grey),
              padding: const EdgeInsets.symmetric(horizontal: 4), constraints: const BoxConstraints(),
            ),

            IconButton(
              onPressed: _sharePost,
              icon: const Icon(Icons.share, color: Colors.blueGrey),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
            
            if (widget.isOwner)
              IconButton(
                onPressed: () => _editPostPopUp(context), 
                icon: const Icon(Icons.edit, color: Colors.blue),
                padding: const EdgeInsets.symmetric(horizontal: 4), constraints: const BoxConstraints(),
              ),

            if (widget.isOwner)
              IconButton(
                onPressed: () => _deletePost(context), icon: const Icon(Icons.delete, color: Colors.red),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}