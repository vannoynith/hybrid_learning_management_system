import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String role;
  final String? username;
  final String? displayName;
  final String? dateOfBirth;
  final String? address;
  final String? phoneNumber;
  final String? position;
  final String? profileImageUrl;
  final String? userSex;
  final DateTime? createdAt;
  final bool active;
  final bool? suspended;
  final DateTime? lastActive;
  final DateTime? passwordUpdatedAt;

  User({
    required this.uid,
    required this.email,
    required this.role,
    this.username,
    this.displayName,
    this.dateOfBirth,
    this.address,
    this.phoneNumber,
    this.position,
    this.profileImageUrl,
    this.userSex,
    this.createdAt,
    required this.active,
    this.suspended,
    this.lastActive,
    this.passwordUpdatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      username: map['username'] as String?,
      displayName: map['displayName'] as String?,
      dateOfBirth: map['dateOfBirth'] as String?,
      address: map['address'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      position: map['position'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      userSex: map['userSex'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      active: map['active'] as bool? ?? true,
      suspended: map['suspended'] as bool?,
      lastActive: (map['lastActive'] as Timestamp?)?.toDate(),
      passwordUpdatedAt: (map['passwordUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'username': username,
      'displayName': displayName,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'phoneNumber': phoneNumber,
      'position': position,
      'profileImageUrl': profileImageUrl,
      'userSex': userSex,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'active': active,
      'suspended': suspended,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }
}
