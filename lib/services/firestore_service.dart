import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:hybridlms/models/course.dart';
import 'package:hybridlms/models/interaction.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart' as firebase_user;
import 'package:file_picker/file_picker.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dsdfxombn', // Replace with your actual Cloudinary API key
    'hybridlms',
    cache: false,
  );

  FirebaseFirestore get db => _db;

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

      // Fetch existing user data
      final userDoc = await _db.collection('users').doc(uid).get();
      final existingData = userDoc.exists ? userDoc.data() ?? {} : {};

      // Prepare updated data, preserving existing fields unless new values are provided
      final updatedData = {
        'uid': uid,
        'email': email,
        'role': role,
        'username': username ?? existingData['username'],
        'displayName': displayName ?? existingData['displayName'],
        'phoneNumber': phoneNumber ?? existingData['phoneNumber'],
        'address': address ?? existingData['address'],
        'position': position ?? existingData['position'],
        'profileImageUrl': profileImageUrl ?? existingData['profileImageUrl'],
        'userSex': userSex ?? existingData['userSex'],
        'dateOfBirth': dateOfBirth ?? existingData['dateOfBirth'],
        'active': active,
        'createdAt': existingData['createdAt'] ?? FieldValue.serverTimestamp(),
        'lastActive':
            existingData['lastActive'] ?? FieldValue.serverTimestamp(),
        if (passwordUpdatedAt != null) 'passwordUpdatedAt': passwordUpdatedAt,
      };

      await _db.runTransaction((transaction) async {
        transaction.set(
          _db.collection('users').doc(uid),
          updatedData,
          SetOptions(merge: true),
        );
        final interaction = Interaction(
          userId: uid,
          action: 'update_user',
          targetId: uid,
          details: 'Updated user: $email',
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

  Future<String> uploadToCloudinary(
    dynamic file,
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

      if (!kIsWeb && file is! String) {
        throw Exception('File must be a path on mobile');
      }
      if (kIsWeb && file is! Uint8List) {
        throw Exception('File must be bytes on web');
      }

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

  Future<void> uploadProfilePicture(
    dynamic file,
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

  Future<void> initializeCollections({bool force = false}) async {
    if (!force) return;
    try {
      await initializeInteractionsCollection();
    } catch (e) {
      throw Exception('Failed to initialize collections: $e');
    }
  }

  Future<void> saveCourse(String lecturerId, Course course) async {
    try {
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      if (course.title.isEmpty) throw Exception('Course title cannot be empty');
      if (course.category != null && course.category!.isEmpty) {
        throw Exception('Course category cannot be empty if provided');
      }

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

  Future<void> saveCourseSubcollections(
    String courseId,
    List<Map<String, dynamic>> modules,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');

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
        // Update or create new modules
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

          // Update existing lessons or add new ones
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

          // Remove lessons that are no longer in the updated data
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
        }

        // Remove modules that are no longer in the updated data
        final newModuleIds =
            modules.map((module) => module['id'] as String).toSet();
        for (var moduleId in existingModuleIds.difference(newModuleIds)) {
          transaction.delete(
            _db
                .collection('courses')
                .doc(courseId)
                .collection('modules')
                .doc(moduleId),
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to save course subcollections: $e');
    }
  }

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

  Future<Course?> getCourse(String courseId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      final doc = await _db.collection('courses').doc(courseId).get();
      final data = doc.data();
      if (data == null) return null;

      final courseData = data as Map<String, dynamic>;

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
              lessonsSnapshot.docs
                  .map(
                    (lessonDoc) => ({
                      'id': lessonDoc.id ?? const Uuid().v4(),
                      'name': lessonDoc['name'] ?? '',
                      'text': lessonDoc['text'] ?? '',
                      'documents': lessonDoc['documents'] ?? [],
                      'videos': lessonDoc['videos'] ?? [],
                      'images': lessonDoc['images'] ?? [],
                      'createdAt':
                          lessonDoc['createdAt'] ??
                          FieldValue.serverTimestamp(),
                    }),
                  )
                  .toList();
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

  Future<void> updateCourse(String lecturerId, Course course) async {
    try {
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      if (course.id.isEmpty) throw Exception('Course ID cannot be empty');
      if (course.title.isEmpty) throw Exception('Course title cannot be empty');
      if (course.category != null && course.category!.isEmpty) {
        throw Exception('Course category cannot be empty if provided');
      }

      final courseDoc = await _db.collection('courses').doc(course.id).get();
      if (!courseDoc.exists) throw Exception('Course not found: ${course.id}');
      final existingData = courseDoc.data() as Map<String, dynamic>? ?? {};
      if (existingData['lecturerId'] != lecturerId) {
        throw Exception('Unauthorized: Not the course lecturer');
      }

      // Fetch existing values to preserve if not updated
      final previousCategory = existingData['category'] as String?;
      final previousPublished = existingData['isPublished'] as bool? ?? false;
      final previousThumbnailUrl = existingData['thumbnailUrl'] as String?;
      final previousModules = existingData['modules'] as List<dynamic>?;
      final previousContentUrls =
          existingData['contentUrls'] as List<dynamic>? ?? [];
      final previousEnrolledCount = existingData['enrolledCount'] as int? ?? 0;

      // Prepare updated data, preserving unchanged fields
      final updatedData = course.toMap();
      updatedData['lastModifiedAt'] = FieldValue.serverTimestamp();
      if (course.modules == null) updatedData['modules'] = previousModules;
      if (course.contentUrls.isEmpty)
        updatedData['contentUrls'] = previousContentUrls;
      if (course.enrolledCount == 0)
        updatedData['enrolledCount'] = previousEnrolledCount;

      final changes = <String>[];
      if (previousCategory != course.category) {
        changes.add(
          'Category changed from $previousCategory to ${course.category}',
        );
      }
      if (course.isPublished != previousPublished) {
        changes.add(
          'Publish status changed to ${course.isPublished ? 'Published' : 'Draft'}',
        );
      }
      if (course.thumbnailUrl != previousThumbnailUrl &&
          course.thumbnailUrl != null) {
        changes.add('Thumbnail updated');
      }

      await _db.runTransaction((transaction) async {
        transaction.set(
          _db.collection('courses').doc(course.id),
          updatedData,
          SetOptions(merge: true),
        );

        if (course.isPublished != previousPublished) {
          transaction.update(_db.collection('courses').doc(course.id), {
            'isPublished': course.isPublished,
            if (course.isPublished) 'publishedAt': FieldValue.serverTimestamp(),
          });
        }

        final interaction = Interaction(
          userId: lecturerId,
          action: 'update_course',
          targetId: course.id,
          details:
              'Updated course: ${course.title}' +
              (changes.isNotEmpty ? ' (${changes.join(', ')})' : ''),
          timestamp: Timestamp.now(),
        );
        transaction.set(
          _db.collection('interactions').doc(),
          interaction.toMap(),
        );
      });

      // Update subcollections only if modules are provided
      if (course.modules != null) {
        await saveCourseSubcollections(course.id, course.modules!);
      }
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }
}
