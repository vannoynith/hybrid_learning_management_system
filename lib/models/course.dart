import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String lecturerId;
  final String token;
  final String category;
  final String? thumbnailUrl;
  final String? previewVideoUrl;
  final Timestamp? createdAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.lecturerId,
    required this.token,
    required this.category,
    this.thumbnailUrl,
    this.previewVideoUrl,
    this.createdAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      lecturerId: map['lecturerId'] as String? ?? '',
      token: map['token'] as String? ?? '',
      category: map['category'] as String? ?? 'New',
      thumbnailUrl: map['thumbnailUrl'] as String?,
      previewVideoUrl: map['previewVideoUrl'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lecturerId': lecturerId,
      'token': token,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'previewVideoUrl': previewVideoUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
