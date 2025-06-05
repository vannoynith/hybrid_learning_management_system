import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final String? description;
  final int order;
  final Timestamp createdAt;

  Lesson({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    this.description,
    required this.order,
    required this.createdAt,
  });

  factory Lesson.fromMap(Map<String, dynamic> map, String id) {
    return Lesson(
      id: id,
      courseId: map['courseId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      order: map['order'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'moduleId': moduleId,
      'title': title,
      'description': description,
      'order': order,
      'createdAt': createdAt,
    };
  }
}
