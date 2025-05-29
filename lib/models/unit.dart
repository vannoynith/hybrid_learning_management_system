import 'package:cloud_firestore/cloud_firestore.dart';

class Unit {
  final String id;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final String title;
  final String type;
  final String url;
  final String description;
  final int order;
  final DateTime? createdAt;

  Unit({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.title,
    required this.type,
    required this.url,
    required this.description,
    required this.order,
    this.createdAt,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      moduleId: map['moduleId'] as String,
      lessonId: map['lessonId'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      url: map['url'] as String,
      description: map['description'] as String,
      order: map['order'] as int,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'title': title,
      'type': type,
      'url': url,
      'description': description,
      'order': order,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
