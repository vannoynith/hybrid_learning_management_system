import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  late final String lecturerId; // Retains the UID, immutable
  late String lecturerDisplayName; // New field for display name, mutable
  final bool isPublished;
  final Timestamp? createdAt;
  final String? thumbnailUrl;
  final List<Map<String, dynamic>>? modules;
  final List<dynamic> contentUrls;
  final int enrolledCount;
  final String? category;
  final double? rating;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.lecturerId,
    required this.lecturerDisplayName,
    this.isPublished = false,
    this.createdAt,
    this.thumbnailUrl,
    this.modules,
    this.contentUrls = const [],
    this.enrolledCount = 0,
    this.category,
    this.rating,
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
      'modules': modules,
      'contentUrls': contentUrls,
      'enrolledCount': enrolledCount,
      'category': category,
      'rating': rating,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      lecturerId: map['lecturerId']?.toString() ?? '',
      lecturerDisplayName: '',
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: map['createdAt'] as Timestamp?,
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      modules: (map['modules'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      contentUrls: map['contentUrls'] as List<dynamic>? ?? [],
      enrolledCount: map['enrolledCount'] as int? ?? 0,
      category: map['category']?.toString(),
      rating: map['rating'] as double?,
    );
  }
}

class Class {
  final String id;
  final String courseId;
  final String token;
  final Timestamp? deadline;
  final Timestamp createdAt;

  Class({
    required this.id,
    required this.courseId,
    required this.token,
    this.deadline,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'token': token,
      'deadline': deadline,
      'createdAt': createdAt,
    };
  }

  factory Class.fromMap(Map<String, dynamic> map, String id) {
    return Class(
      id: id,
      courseId: map['courseId']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
      deadline: map['deadline'] as Timestamp?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
