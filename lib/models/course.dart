import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String? description;
  final String lecturerId;
  final String token;
  final String? category;
  final bool active;
  final String? thumbnailUrl;
  final String? expiryDate;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    required this.lecturerId,
    required this.token,
    this.category,
    required this.active,
    this.thumbnailUrl,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      lecturerId: map['lecturerId'] ?? '',
      token: map['token'] ?? '',
      category: map['category'],
      active: map['active'] ?? false,
      thumbnailUrl: map['thumbnailUrl'],
      expiryDate: map['expiryDate'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'lecturerId': lecturerId,
      'token': token,
      'category': category,
      'active': active,
      'thumbnailUrl': thumbnailUrl,
      'expiryDate': expiryDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
