import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/models/interaction.dart';
import 'package:uuid/uuid.dart';

import 'package:file_picker/file_picker.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dsdfxombn', // Replace with your actual Cloudinary API key
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
    DateTime? passwordUpdatedAt,
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

  /// Uploads a file to Cloudinary and returns the secure URL.
  Future<String> uploadToCloudinary(
    dynamic file, // String for mobile, Uint8List for web
    String type,
    String userId, {
    bool isProfilePic = false,
    bool isThumbnail = false,
    String? courseId,
    String? moduleId,
  }) async {
    try {
      if (file == null) throw Exception('File cannot be null');
      if (!['image', 'pdf', 'video', 'doc'].contains(type)) {
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

      // Validate file path on non-web platforms
      if (!kIsWeb && file is String) {
        final filePath = file as String;
        if (filePath.isEmpty || !await File(filePath).exists()) {
          throw Exception('File path not found: $filePath');
        }
        final fileSize = await File(filePath).length();
        if (fileSize > 100 * 1024 * 1024) {
          throw Exception('File size exceeds 100MB limit');
        }
      } else if (kIsWeb && file is Uint8List) {
        if (file.length > 100 * 1024 * 1024) {
          throw Exception('File size exceeds 100MB limit');
        }
      }

      // Define folder structure
      String folderPath = 'hybridlms';
      if (isProfilePic) {
        folderPath += '/users/$userId/profile';
      } else if (isThumbnail) {
        folderPath += '/courses/$courseId/thumbnail';
      } else if (courseId != null && moduleId != null) {
        folderPath += '/courses/$courseId/$moduleId/$type';
      } else {
        folderPath += '/users/$userId/uploads/$type';
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
            resourceType:
                type == 'image'
                    ? CloudinaryResourceType.Image
                    : type == 'video'
                    ? CloudinaryResourceType.Video
                    : CloudinaryResourceType.Raw,
          ),
        );
      } else if (kIsWeb && file is Uint8List) {
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            file,
            folder: folderPath,
            publicId: publicId,
            resourceType:
                type == 'image'
                    ? CloudinaryResourceType.Image
                    : type == 'video'
                    ? CloudinaryResourceType.Video
                    : CloudinaryResourceType.Raw,
            identifier: publicId,
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
        action:
            isProfilePic
                ? 'upload_profile_picture'
                : isThumbnail
                ? 'upload_thumbnail'
                : 'upload_$type',
        targetId: isProfilePic ? userId : courseId ?? userId,
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
      if (userId != adminUid &&
          (!adminDoc.exists || adminDoc.get('role') != 'admin')) {
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

  /// Uploads a course thumbnail to Cloudinary and returns the secure URL.
  Future<String> uploadCourseThumbnail(
    dynamic file,
    String courseId,
    String lecturerId,
  ) async {
    try {
      if (file == null) throw Exception('File cannot be null');
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');

      final url = await uploadToCloudinary(
        file,
        'image',
        lecturerId,
        isThumbnail: true,
        courseId: courseId,
      );
      return url;
    } catch (e) {
      throw Exception('Failed to upload course thumbnail: $e');
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

  /// Creates or updates a course in Firestore with modules and lesson content.
  Future<void> saveCourse(String lecturerId, Course course) async {
    try {
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      if (course.title.isEmpty) throw Exception('Course title cannot be empty');
      if (course.category != null && course.category!.isEmpty) {
        throw Exception('Course category cannot be empty if provided');
      }

      // Perform all reads outside the transaction
      final courseDoc = await _db.collection('courses').doc(course.id).get();
      final previousCategory =
          courseDoc.exists && courseDoc.data() != null
              ? courseDoc.data()!['category'] as String?
              : null;

      await _db.runTransaction((transaction) async {
        final courseData = course.toMap();
        courseData['lastModifiedAt'] = FieldValue.serverTimestamp();
        transaction.set(_db.collection('courses').doc(course.id), courseData);

        final interaction = Interaction(
          userId: lecturerId,
          action: course.createdAt == null ? 'create_course' : 'update_course',
          targetId: course.id,
          details:
              '${course.createdAt == null ? 'Created' : 'Updated'} course: ${course.title}' +
              (previousCategory != course.category
                  ? ' (Category changed from $previousCategory to ${course.category})'
                  : ''),
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to save course: $e');
    }
  }

  /// Saves modules and lessons as subcollections in Firestore.
  Future<void> saveCourseSubcollections(
    String courseId,
    List<Map<String, dynamic>> modules,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');

      // Perform all reads outside the transaction
      final existingModulesSnapshot =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .get();
      final existingModuleIds =
          existingModulesSnapshot.docs.map((doc) => doc.id).toSet();

      final existingLessonsMap = <String, Set<String>>{};
      for (var moduleDoc in existingModulesSnapshot.docs) {
        final moduleId = moduleDoc.id;
        final lessonsSnapshot =
            await _db
                .collection('courses')
                .doc(courseId)
                .collection('modules')
                .doc(moduleId)
                .collection('lessons')
                .get();
        existingLessonsMap[moduleId] =
            lessonsSnapshot.docs.map((doc) => doc.id).toSet();
      }

      await _db.runTransaction((transaction) async {
        // Perform all writes after reads
        final newModuleIds =
            modules.map((module) => module['id'] as String).toSet();

        // Delete modules that are no longer present
        for (var moduleId in existingModuleIds.difference(newModuleIds)) {
          transaction.delete(
            _db
                .collection('courses')
                .doc(courseId)
                .collection('modules')
                .doc(moduleId),
          );
        }

        for (var module in modules) {
          final moduleId = module['id'] ?? const Uuid().v4();
          transaction.set(
            _db
                .collection('courses')
                .doc(courseId)
                .collection('modules')
                .doc(moduleId),
            {
              'id': moduleId,
              'name': module['name'] ?? '',
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          final existingLessonIds = existingLessonsMap[moduleId] ?? {};
          final newLessonIds =
              (module['lessons'] as List<dynamic>?)
                  ?.map((lesson) => lesson['id'] as String)
                  .toSet() ??
              {};

          // Delete lessons that are no longer present
          for (var lessonId in existingLessonIds.difference(newLessonIds)) {
            transaction.delete(
              _db
                  .collection('courses')
                  .doc(courseId)
                  .collection('modules')
                  .doc(moduleId)
                  .collection('lessons')
                  .doc(lessonId),
            );
          }

          for (var lesson in module['lessons'] ?? []) {
            final lessonId = lesson['id'] ?? const Uuid().v4();
            transaction.set(
              _db
                  .collection('courses')
                  .doc(courseId)
                  .collection('modules')
                  .doc(moduleId)
                  .collection('lessons')
                  .doc(lessonId),
              {
                'id': lessonId,
                'name': lesson['name'] ?? '',
                'text': lesson['text'] ?? '',
                'documents': lesson['documents'] ?? [],
                'videos': lesson['videos'] ?? [],
                'images': lesson['images'] ?? [],
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to save course subcollections: $e');
    }
  }

  /// Publishes a course by setting its published status to true.
  Future<void> publishCourse(String courseId, String lecturerId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      final courseData = courseDoc.data();
      if (courseData == null) throw Exception('Course data is null');
      if (courseData['lecturerId'] != lecturerId) {
        throw Exception('Unauthorized: Not the course lecturer');
      }

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('courses').doc(courseId), {
          'isPublished': true,
          'publishedAt': FieldValue.serverTimestamp(),
        });
        final interaction = Interaction(
          userId: lecturerId,
          action: 'publish_course',
          targetId: courseId,
          details: 'Published course: ${courseData['title'] ?? courseId}',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to publish course: $e');
    }
  }

  /// Disables a course by setting its published status to false.
  Future<void> disableCourse(String courseId, String lecturerId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      final courseData = courseDoc.data();
      if (courseData == null) throw Exception('Course data is null');
      if (courseData['lecturerId'] != lecturerId) {
        throw Exception('Unauthorized: Not the course lecturer');
      }

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('courses').doc(courseId), {
          'isPublished': false,
        });
        final interaction = Interaction(
          userId: lecturerId,
          action: 'disable_course',
          targetId: courseId,
          details: 'Disabled course: ${courseData['title'] ?? courseId}',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to disable course: $e');
    }
  }

  /// Deletes a course and logs the interaction.
  Future<void> deleteCourse(String courseId, String lecturerId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      final courseData = courseDoc.data();
      if (courseData == null) throw Exception('Course data is null');
      if (courseData['lecturerId'] != lecturerId) {
        throw Exception('Unauthorized: Not the course lecturer');
      }

      await _db.runTransaction((transaction) async {
        transaction.delete(_db.collection('courses').doc(courseId));
        final interaction = Interaction(
          userId: lecturerId,
          action: 'delete_course',
          targetId: courseId,
          details: 'Deleted course: ${courseData['title'] ?? courseId}',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  /// Retrieves a course by ID with modules and lessons.
  Future<Course?> getCourse(String courseId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      final doc = await _db.collection('courses').doc(courseId).get();
      final data = doc.data();
      if (data == null) return null;

      final courseData = data as Map<String, dynamic>;

      // Fetch modules and lessons from subcollections
      final modulesSnapshot =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .get();
      final modules = <Map<String, dynamic>>[];
      for (var moduleDoc in modulesSnapshot.docs) {
        final moduleData = moduleDoc.data() as Map<String, dynamic>;
        final lessonsSnapshot =
            await _db
                .collection('courses')
                .doc(courseId)
                .collection('modules')
                .doc(moduleData['id'])
                .collection('lessons')
                .get();
        final lessons =
            lessonsSnapshot.docs.map((lessonDoc) {
              final lessonData = lessonDoc.data() as Map<String, dynamic>;
              return {
                'id': lessonData['id'] ?? const Uuid().v4(),
                'name': lessonData['name'] ?? '',
                'text': lessonData['text'] ?? '',
                'documents': lessonData['documents'] ?? [],
                'videos': lessonData['videos'] ?? [],
                'images': lessonData['images'] ?? [],
                'createdAt':
                    lessonData['createdAt'] ?? FieldValue.serverTimestamp(),
              };
            }).toList();
        modules.add({
          'id': moduleData['id'],
          'name': moduleData['name'],
          'lessons': lessons,
          'createdAt': moduleData['createdAt'] ?? FieldValue.serverTimestamp(),
        });
      }
      courseData['modules'] = modules.isEmpty ? null : modules;

      return Course.fromMap(courseData, doc.id);
    } catch (e) {
      throw Exception('Failed to get course: $e');
    }
  }

  /// Retrieves all courses for a lecturer with optional category filter.
  Future<List<Course>> getLecturerCourses(
    String lecturerId, {
    String? category,
  }) async {
    try {
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      Query query = _db
          .collection('courses')
          .where('lecturerId', isEqualTo: lecturerId)
          .orderBy('createdAt', descending: true);
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      final querySnapshot = await query.get();
      final courses = <Course>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final courseData = data as Map<String, dynamic>;

        final modulesSnapshot =
            await _db
                .collection('courses')
                .doc(doc.id)
                .collection('modules')
                .get();
        final modules = <Map<String, dynamic>>[];
        for (var moduleDoc in modulesSnapshot.docs) {
          final moduleData = moduleDoc.data() as Map<String, dynamic>;
          final lessonsSnapshot =
              await _db
                  .collection('courses')
                  .doc(doc.id)
                  .collection('modules')
                  .doc(moduleData['id'])
                  .collection('lessons')
                  .get();
          final lessons =
              lessonsSnapshot.docs.map((lessonDoc) {
                final lessonData = lessonDoc.data() as Map<String, dynamic>;
                return {
                  'id': lessonData['id'] ?? const Uuid().v4(),
                  'name': lessonData['name'] ?? '',
                  'text': lessonData['text'] ?? '',
                  'documents': lessonData['documents'] ?? [],
                  'videos': lessonData['videos'] ?? [],
                  'images': lessonData['images'] ?? [],
                  'createdAt':
                      lessonData['createdAt'] ?? FieldValue.serverTimestamp(),
                };
              }).toList();
          modules.add({
            'id': moduleData['id'],
            'name': moduleData['name'],
            'lessons': lessons,
            'createdAt':
                moduleData['createdAt'] ?? FieldValue.serverTimestamp(),
          });
        }
        courseData['modules'] = modules.isEmpty ? null : modules;
        courses.add(Course.fromMap(courseData, doc.id));
      }
      return courses;
    } catch (e) {
      throw Exception('Failed to get lecturer courses: $e');
    }
  }

  /// Enrolls a student in a course.
  Future<void> enrollStudent(String courseId, String studentId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (studentId.isEmpty) throw Exception('Student ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      final userDoc = await _db.collection('users').doc(studentId).get();
      if (!userDoc.exists || userDoc.get('role') != 'student') {
        throw Exception('Invalid or non-student user: $studentId');
      }

      await _db.runTransaction((transaction) async {
        final enrollmentRef = _db
            .collection('enrollments')
            .doc('$courseId-$studentId');
        transaction.set(enrollmentRef, {
          'courseId': courseId,
          'studentId': studentId,
          'enrolledAt': FieldValue.serverTimestamp(),
        });
        transaction.update(_db.collection('courses').doc(courseId), {
          'enrolledCount': FieldValue.increment(1),
        });
        final interaction = Interaction(
          userId: studentId,
          action: 'enroll_course',
          targetId: courseId,
          details: 'Student enrolled in course: $courseId',
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to enroll student: $e');
    }
  }

  /// Retrieves enrolled students for a course.
  Future<List<Map<String, dynamic>>> getEnrolledStudents(
    String courseId,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      final querySnapshot =
          await _db
              .collection('enrollments')
              .where('courseId', isEqualTo: courseId)
              .get();
      final studentIds =
          querySnapshot.docs.map((doc) => doc['studentId'] as String).toList();
      final students = <Map<String, dynamic>>[];
      for (var studentId in studentIds) {
        final user = await getUser(studentId);
        if (user != null) students.add(user);
      }
      return students;
    } catch (e) {
      throw Exception('Failed to get enrolled students: $e');
    }
  }

  /// Updates an existing course with new details and modules.
  Future<void> updateCourse(String lecturerId, Course course) async {
    try {
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      if (course.id.isEmpty) throw Exception('Course ID cannot be empty');
      if (course.title.isEmpty) throw Exception('Course title cannot be empty');
      if (course.category != null && course.category!.isEmpty) {
        throw Exception('Course category cannot be empty if provided');
      }

      // Perform all reads outside the transaction
      final courseDoc = await _db.collection('courses').doc(course.id).get();
      if (!courseDoc.exists) throw Exception('Course not found: ${course.id}');
      final courseData = courseDoc.data();
      if (courseData == null) throw Exception('Course data is null');
      if (courseData['lecturerId'] != lecturerId) {
        throw Exception('Unauthorized: Not the course lecturer');
      }
      final previousCategory = courseData['category'] as String?;
      final previousPublished = courseData['isPublished'] as bool?;

      await _db.runTransaction((transaction) async {
        final courseDataToUpdate = course.toMap();
        courseDataToUpdate['lastModifiedAt'] = FieldValue.serverTimestamp();
        transaction.update(
          _db.collection('courses').doc(course.id),
          courseDataToUpdate,
        );

        // Handle publish status change
        if (course.isPublished != previousPublished) {
          transaction.update(_db.collection('courses').doc(course.id), {
            'isPublished': course.isPublished,
            if (course.isPublished) 'publishedAt': FieldValue.serverTimestamp(),
          });
        }

        // Save or update subcollections
        await saveCourseSubcollections(course.id, course.modules ?? []);

        final interaction = Interaction(
          userId: lecturerId,
          action: 'update_course',
          targetId: course.id,
          details:
              'Updated course: ${course.title}' +
              (previousCategory != course.category
                  ? ' (Category changed from $previousCategory to ${course.category})'
                  : '') +
              (course.isPublished != previousPublished
                  ? ' (Publish status changed to ${course.isPublished ? 'Published' : 'Draft'})'
                  : ''),
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }
}
