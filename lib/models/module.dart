import 'package:cloud_firestore/cloud_firestore.dart';

class Module {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int order;
  final DateTime? createdAt;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.order,
    this.createdAt,
  });

  factory Module.fromMap(Map<String, dynamic> map) {
    return Module(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      order: map['order'] as int,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'order': order,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
