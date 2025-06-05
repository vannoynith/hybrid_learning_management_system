import 'package:cloud_firestore/cloud_firestore.dart';

class Module {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int order;
  final Timestamp createdAt;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.order,
    required this.createdAt,
  });

  factory Module.fromMap(Map<String, dynamic> map, String id) {
    return Module(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      order: map['order'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'order': order,
      'createdAt': createdAt,
    };
  }
}
