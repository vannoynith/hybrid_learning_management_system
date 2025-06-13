import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String lecturerId;
  final bool isPublished;
  final Timestamp? createdAt;
  final String? thumbnailUrl;
  final List<Map<String, dynamic>>? modules;
  final List<dynamic> contentUrls;
  final int enrolledCount;
  final String? category;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.lecturerId,
    this.isPublished = false,
    this.createdAt,
    this.thumbnailUrl,
    this.modules,
    this.contentUrls = const [],
    this.enrolledCount = 0,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lecturerId': lecturerId,
      'isPublished': isPublished,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'thumbnailUrl': thumbnailUrl,
      'contentUrls': contentUrls,
      'enrolledCount': enrolledCount,
      'category': category,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      lecturerId: map['lecturerId']?.toString() ?? '',
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp?,
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      modules: (map['modules'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      contentUrls: map['contentUrls'] as List<dynamic>? ?? [],
      enrolledCount: map['enrolledCount'] as int? ?? 0,
      category: map['category']?.toString(),
    );
  }
}
