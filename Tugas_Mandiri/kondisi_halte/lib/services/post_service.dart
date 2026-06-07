import 'package:kondisi_halte/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _postsCollection = _database.collection(
    'posts',
  );

  static Future<void> addPost(Post post) async {
    Map<String, dynamic> newPost = {
      'image': post.image,
      'description': post.description,
      'category': post.category,
      'latitude': post.latitude,
      'longitude': post.longitude,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'user_id': post.userId,
      'user_full_name': post.userFullName,
    };
    await _postsCollection.add(newPost);
  }

  static Future<void> updatePost(Post post) async {
    Map<String, dynamic> updatedPost = {
      'image': post.image,
      'description': post.description,
      'category': post.category,
      'latitude': post.latitude,
      'longitude': post.longitude,
      'created_at': post.createdAt,
      'updated_at': FieldValue.serverTimestamp(),
      'user_id': post.userId,
      'user_full_name': post.userFullName,
    };

    await _postsCollection.doc(post.id).update(updatedPost);
  }

  static Future<void> deletePost(Post post) async {
    await _postsCollection.doc(post.id).delete();
  }

  static Future<QuerySnapshot> retrievePost() {
    return _postsCollection.get();
  }

  static Stream<List<Post>> getPostList() {
    return _postsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Post(
          id: doc.id,
          image: data['image'],
          description: data['description'],
          category: data['category'],
          createdAt: data['created_at'] != null
              ? data['created_at'] as Timestamp
              : null,
          updatedAt: data['updated_at'] != null
              ? data['updated_at'] as Timestamp
              : null,
          latitude: data['latitude'],
          longitude: data['longitude'],
          userId: data['user_id'],
          userFullName: data['user_full_name'],
        );
      }).toList();
    });
  }
}