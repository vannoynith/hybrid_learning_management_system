import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/user.dart' as firebase_user;
import '../models/interaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dsdfxombn',
    'hybridlms',
    cache: false,
  );

  FirebaseFirestore get db => _db;

  /// Initializes the interactions collection with a sample entry if empty.
  Future<void> initializeInteractionsCollection() async {
    try {
      final interactionsSnapshot =
          await _db.collection('interactions').limit(1).get();
      if (interactionsSnapshot.docs.isEmpty) {
        final sampleInteraction = Interaction(
          userId: 'system',
          action: 'initialize',
          details: 'Interactions collection initialized',
          timestamp: Timestamp.now(),
        );
        await _db.collection('interactions').add(sampleInteraction.toMap());
      }
    } catch (e) {
      throw Exception('Failed to initialize interactions collection: $e');
    }
  }

  /// Saves a user to Firestore with the specified details.
  Future<void> saveUser(
    String uid,
    String email,
    String role, {
    String? username,
    String? displayName,
    String? phoneNumber,
    String? address,
    String? position,
    String? profileImageUrl,
    String? userSex,
    String? dateOfBirth,
    bool active = true,
  }) async {
    try {
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      if (email.isEmpty) throw Exception('Email cannot be empty');
      if (!['admin', 'lecturer', 'student'].contains(role)) {
        throw Exception('Invalid role: $role');
      }
      await _db.runTransaction((transaction) async {
        transaction.set(_db.collection('users').doc(uid), {
          'uid': uid,
          'email': email,
          'role': role,
          'username': username,
          'displayName': displayName,
          'phoneNumber': phoneNumber,
          'address': address,
          'position': position,
          'profileImageUrl': profileImageUrl,
          'userSex': userSex,
          'dateOfBirth': dateOfBirth,
          'active': active,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        final interaction = Interaction(
          userId: uid,
          action: 'create_user',
          targetId: uid,
          details: 'Created user: $email',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  /// Updates the lastActive timestamp for a user.
  Future<void> updateLastActive(String uid) async {
    try {
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(uid), {
          'lastActive': FieldValue.serverTimestamp(),
        });
        final interaction = Interaction(
          userId: uid,
          action: 'update_last_active',
          targetId: uid,
          details: 'Updated last active timestamp for user: $uid',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to update last active: $e');
    }
  }

  /// Marks a user as inactive (soft delete) and logs the interaction.
  Future<void> deleteUser(String uid, String adminUid) async {
    try {
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      if (adminUid.isEmpty) throw Exception('Admin UID cannot be empty');
      final adminDoc = await _db.collection('users').doc(adminUid).get();
      if (!adminDoc.exists || adminDoc.get('role') != 'admin') {
        throw Exception('Invalid or non-admin user: $adminUid');
      }
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception('User not found: $uid');
      final userData = userDoc.data();
      if (userData == null) throw Exception('User data is null');

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(uid), {'active': false});
        final interaction = Interaction(
          userId: adminUid,
          action: 'delete_user',
          targetId: uid,
          details: 'Deleted user: ${userData['email'] ?? uid}',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Suspends a user by setting their suspended status to true and logs the interaction.
  Future<void> suspendUser(String uid, String adminUid) async {
    try {
      if (uid.isEmpty) throw Exception('User ID cannot be empty');
      if (adminUid.isEmpty) throw Exception('Admin UID cannot be empty');
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) throw Exception('User not found: $uid');
      final userData = doc.data();
      if (userData == null) throw Exception('User data is null');

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(uid), {
          'suspended': true,
        });
        final interaction = Interaction(
          userId: adminUid,
          action: 'suspend_user',
          targetId: uid,
          details: 'Suspended user: ${userData['email'] ?? uid}',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  /// Unsuspends a user by setting their suspended status to false and logs the interaction.
  Future<void> unsuspendUser(String uid, String adminUid) async {
    try {
      if (uid.isEmpty) throw Exception('User ID cannot be empty');
      if (adminUid.isEmpty) throw Exception('Admin UID cannot be empty');
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) throw Exception('User not found: $uid');
      final userData = doc.data();
      if (userData == null) throw Exception('User data is null');

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(uid), {
          'suspended': false,
        });
        final interaction = Interaction(
          userId: adminUid,
          action: 'unsuspend_user',
          targetId: uid,
          details: 'Unsuspended user: ${userData['email'] ?? uid}',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to unsuspend user: $e');
    }
  }

  /// Retrieves a user's data by UID.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      return data != null ? data as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Retrieves a paginated list of active users with optional role filtering.
  Future<List<Map<String, dynamic>>> getActiveUsers({
    List<String>? roles,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _db.collection('users').where('active', isEqualTo: true);
      if (roles != null && roles.isNotEmpty) {
        if (roles.any(
          (role) => !['admin', 'lecturer', 'student'].contains(role),
        )) {
          throw Exception('Invalid role in filter');
        }
        query = query.where('role', whereIn: roles);
      }
      query = query.limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get active users: $e');
    }
  }

  /// Searches users by email prefix and optional role filter.
  Future<List<Map<String, dynamic>>> searchUsersByEmail(
    String emailQuery, {
    List<String>? roles,
    int limit = 50,
  }) async {
    try {
      if (emailQuery.isEmpty) return [];
      Query query = _db.collection('users').where('active', isEqualTo: true);
      if (roles != null && roles.isNotEmpty) {
        if (roles.any(
          (role) => !['admin', 'lecturer', 'student'].contains(role),
        )) {
          throw Exception('Invalid role in filter');
        }
        query = query.where('role', whereIn: roles);
      }
      query = query
          .where('email', isGreaterThanOrEqualTo: emailQuery.toLowerCase())
          .where('email', isLessThan: '${emailQuery.toLowerCase()}\uf8ff')
          .limit(limit);
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Uploads a file to Cloudinary for profile pictures and returns the secure URL.
  Future<String> uploadToCloudinary(
    dynamic file, // String for mobile, Uint8List for web
    String type,
    String userId, {
    bool isProfilePic = false,
  }) async {
    try {
      if (file == null) throw Exception('File cannot be null');
      if (!['image'].contains(type)) {
        throw Exception('Invalid content type: $type');
      }
      if (userId.isEmpty) throw Exception('User ID cannot be empty');

      // Validate file type based on platform
      if (!kIsWeb && file is! String) {
        throw Exception('File must be a path on mobile');
      }
      if (kIsWeb && file is! Uint8List) {
        throw Exception('File must be bytes on web');
      }

      // Validate file size
      if (!kIsWeb && file is String) {
        final fileSize = await File(file).length();
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('File size exceeds 10MB limit');
        }
      } else if (kIsWeb && file is Uint8List) {
        if (file.length > 10 * 1024 * 1024) {
          throw Exception('File size exceeds 10MB limit');
        }
      }

      // Define folder structure
      String folderPath = 'hybridlms';
      if (isProfilePic) {
        folderPath += '/users/$userId/profile';
      } else {
        folderPath += '/users/$userId/uploads';
      }

      // Generate unique public ID
      final publicId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      CloudinaryResponse response;
      if (!kIsWeb && file is String) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file,
            folder: folderPath,
            publicId: publicId,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      } else if (kIsWeb && file is Uint8List) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            file,
            folder: folderPath,
            publicId: publicId,
            resourceType: CloudinaryResourceType.Image,
            identifier: publicId, // Added meaningful identifier
          ),
        );
      } else {
        throw Exception('Unsupported file type or platform');
      }

      if (response.secureUrl == null) {
        throw Exception('Failed to upload file to Cloudinary');
      }

      // Log the interaction
      final interaction = Interaction(
        userId: userId,
        action: isProfilePic ? 'upload_profile_picture' : 'upload_file',
        targetId: userId,
        details: 'Uploaded $type to $folderPath/$publicId',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);

      return response.secureUrl!;
    } catch (e) {
      throw Exception('Failed to upload to Cloudinary: $e');
    }
  }

  /// Uploads a profile picture for a user and updates the user document.
  Future<void> uploadProfilePicture(
    dynamic file, // String for mobile, Uint8List for web
    String userId,
    String adminUid,
  ) async {
    try {
      if (userId.isEmpty) throw Exception('User ID cannot be empty');
      if (adminUid.isEmpty) throw Exception('Admin UID cannot be empty');
      final adminDoc = await _db.collection('users').doc(adminUid).get();
      if (!adminDoc.exists || adminDoc.get('role') != 'admin') {
        throw Exception('Invalid or non-admin user: $adminUid');
      }
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found: $userId');

      final url = await uploadToCloudinary(
        file,
        'image',
        userId,
        isProfilePic: true,
      );

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(userId), {
          'profileImageUrl': url,
          'lastModifiedAt': FieldValue.serverTimestamp(),
        });
        final interaction = Interaction(
          userId: adminUid,
          action: 'update_profile_picture',
          targetId: userId,
          details: 'Updated profile picture for user: $userId',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Logs an interaction to the interactions collection.
  Future<void> logInteraction(Interaction interaction) async {
    try {
      if (interaction.userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      if (interaction.action.isEmpty) {
        throw Exception('Action cannot be empty');
      }
      await _db.collection('interactions').add(interaction.toMap());
    } catch (e) {
      throw Exception('Failed to log interaction: $e');
    }
  }

  /// Retrieves interactions for a user, skipping malformed documents, and fetches user names.
  Future<List<Interaction>> getInteractions(String userId) async {
    try {
      if (userId.isEmpty) throw Exception('User ID cannot be empty');
      final querySnapshot =
          await _db
              .collection('interactions')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

      final interactions = <Interaction>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (data['userId'] is String &&
              data['action'] is String &&
              data['timestamp'] is Timestamp) {
            String? adminName;
            final adminDoc =
                await _db.collection('users').doc(data['userId']).get();
            if (adminDoc.exists) {
              final adminData = adminDoc.data();
              adminName =
                  adminData != null
                      ? adminData['email']?.split('@')[0] ?? 'Unknown Admin'
                      : 'Unknown Admin';
            }

            String? targetName;
            if (data['targetId'] != null) {
              final targetDoc =
                  await _db.collection('users').doc(data['targetId']).get();
              if (targetDoc.exists) {
                final targetData = targetDoc.data();
                targetName =
                    targetData != null
                        ? targetData['email']?.split('@')[0] ?? 'Unknown User'
                        : 'Unknown User';
              }
            }

            interactions.add(
              Interaction(
                userId: data['userId'],
                action: data['action'],
                targetId: data['targetId'],
                details: data['details'],
                timestamp: data['timestamp'],
                adminName: adminName,
                targetName: targetName,
              ),
            );
          }
        } catch (e) {
          // Skip malformed documents
        }
      }
      return interactions;
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        throw Exception(
          'Failed to get interactions: The query requires an index. Please create it in the Firebase Console at https://console.firebase.google.com/project/al-learn-db/firestore/indexes.',
        );
      }
      throw Exception('Failed to get interactions: $e');
    }
  }

  /// Initializes Firestore with sample data (optional, for testing).
  Future<void> initializeCollections({bool force = false}) async {
    if (!force) return;
    try {
      await initializeInteractionsCollection();
    } catch (e) {
      throw Exception('Failed to initialize collections: $e');
    }
  }
}
