import 'package:cloud_firestore/cloud_firestore.dart';

class Interaction {
  final String userId;
  final String action;
  final String? targetId;
  final String? details;
  final String? courseId;
  final Timestamp timestamp;
  final String? adminName; // New field for admin's name
  final String? targetName; // New field for target's name

  Interaction({
    required this.userId,
    required this.action,
    this.targetId,
    this.details,
    this.courseId,
    required this.timestamp,
    this.adminName,
    this.targetName,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'targetId': targetId,
      'details': details,
      'courseId': courseId,
      'timestamp': timestamp,
      'adminName': adminName,
      'targetName': targetName,
    };
  }

  factory Interaction.fromMap(Map<String, dynamic> map) {
    return Interaction(
      userId: map['userId'] as String,
      action: map['action'] as String,
      targetId: map['targetId'] as String?,
      details: map['details'] as String?,
      courseId: map['courseId'] as String?,
      timestamp: map['timestamp'] as Timestamp,
      adminName: map['adminName'] as String?,
      targetName: map['targetName'] as String?,
    );
  }
}
