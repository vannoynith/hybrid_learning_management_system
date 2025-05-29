import 'package:cloud_firestore/cloud_firestore.dart';

class Lecturer {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? major;
  final String? degree;
  final String? sex;
  final String? profileImageUrl; // New field for profile image
  final DateTime? createdAt;

  Lecturer({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.major,
    this.degree,
    this.sex,
    this.profileImageUrl,
    this.createdAt,
  });

  factory Lecturer.fromMap(Map<String, dynamic> map) {
    return Lecturer(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      major:
          map['address']
              as String?, // Using address as major from create_lecturer_page
      degree: map['position'] as String?,
      sex: map['dateOfBirth'] as String?, // Using dateOfBirth as sex
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'address': major,
      'position': degree,
      'dateOfBirth': sex,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
    };
  }
}
