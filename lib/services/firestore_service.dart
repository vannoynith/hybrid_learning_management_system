import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/user.dart' as firebase_user;
import '../models/course.dart';

import '../models/interaction.dart';
import '../models/lecturer.dart';
import '../models/module.dart';
import '../models/lesson.dart';
import '../models/unit.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'your_cloud_name',
    'your_upload_preset',
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
    String? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? position,
  }) async {
    try {
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      if (email.isEmpty) throw Exception('Email cannot be empty');
      if (!['student', 'admin', 'lecturer'].contains(role)) {
        throw Exception('Invalid role: $role');
      }
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'role': role,
        'displayName': displayName ?? username ?? email.split('@')[0],
        'dateOfBirth': dateOfBirth,
        'address': address,
        'phoneNumber': phoneNumber,
        'position': position,
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
        'suspended': false,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  /// Updates the lastActive timestamp for a user.
  Future<void> updateLastActive(String uid) async {
    try {
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      await _db.collection('users').doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
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

      // Verify admin exists and has admin role
      final adminDoc = await _db.collection('users').doc(adminUid).get();
      if (!adminDoc.exists || adminDoc.get('role') != 'admin') {
        throw Exception('Invalid or non-admin user: $adminUid');
      }

      // Verify target user exists
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception('User not found: $uid');

      final userData = userDoc.data() as Map<String, dynamic>;
      await _db.collection('users').doc(uid).update({'active': false});

      // Log the interaction
      final interaction = Interaction(
        userId: adminUid,
        action: 'delete_user',
        targetId: uid,
        details: 'Deleted user: ${userData['email'] ?? uid}',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
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

      final userData = doc.data() as Map<String, dynamic>;
      await _db.collection('users').doc(uid).update({'suspended': true});

      // Log the interaction
      final interaction = Interaction(
        userId: adminUid,
        action: 'suspend_user',
        targetId: uid,
        details: 'Suspended user: ${userData['email'] ?? uid}',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
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

      final userData = doc.data() as Map<String, dynamic>;
      await _db.collection('users').doc(uid).update({'suspended': false});

      // Log the interaction
      final interaction = Interaction(
        userId: adminUid,
        action: 'unsuspend_user',
        targetId: uid,
        details: 'Unsuspended user: ${userData['email'] ?? uid}',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
    } catch (e) {
      throw Exception('Failed to unsuspend user: $e');
    }
  }

  /// Retrieves a user's data by UID.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      if (uid.isEmpty) throw Exception('UID cannot be empty');
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
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
        query = query.where('role', whereIn: roles);
      }
      query = query.limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      QuerySnapshot querySnapshot = await query.get();
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
        query = query.where('role', whereIn: roles);
      }
      query = query
          .where('email', isGreaterThanOrEqualTo: emailQuery.toLowerCase())
          .where('email', isLessThan: '${emailQuery.toLowerCase()}\uf8ff')
          .limit(limit);
      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Creates a new course with validation and assigns it an ID.
  Future<void> createCourse(
    String title,
    String description,
    String lecturerId,
    String token, {
    String category = 'New',
  }) async {
    try {
      if (title.isEmpty) throw Exception('Title cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final lecturerDoc = await _db.collection('users').doc(lecturerId).get();
      if (!lecturerDoc.exists || lecturerDoc.get('role') != 'lecturer') {
        throw Exception('Invalid or non-existent lecturer: $lecturerId');
      }
      DocumentReference docRef = await _db.collection('courses').add({
        'title': title,
        'description': description,
        'lecturerId': lecturerId,
        'token': token,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await docRef.update({'id': docRef.id});

      // Log the interaction
      final interaction = Interaction(
        userId: lecturerId,
        action: 'create_course',
        targetId: docRef.id,
        courseId: docRef.id,
        details: 'Created course: $title',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  /// Adds a material to a course with validation.
  Future<void> addCourseMaterial(
    String courseId,
    String type,
    String url,
    String lecturerId,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (type.isEmpty) throw Exception('Type cannot be empty');
      if (url.isEmpty) throw Exception('URL cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      await _db.collection('courses').doc(courseId).collection('materials').add(
        {'type': type, 'url': url, 'uploadedAt': FieldValue.serverTimestamp()},
      );

      // Log the interaction
      final interaction = Interaction(
        userId: lecturerId,
        action: 'upload_material',
        targetId: courseId,
        courseId: courseId,
        details: 'Uploaded material to course: $courseId',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
    } catch (e) {
      throw Exception('Failed to add material: $e');
    }
  }

  /// Uploads a file to Cloudinary and returns the secure URL.
  Future<String> uploadToCloudinary(String filePath, String type) async {
    try {
      if (filePath.isEmpty) throw Exception('File path cannot be empty');
      if (!['video', 'pdf', 'image'].contains(type)) {
        throw Exception('Invalid content type: $type');
      }
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType:
              type == 'video'
                  ? CloudinaryResourceType.Video
                  : type == 'image'
                  ? CloudinaryResourceType.Image
                  : CloudinaryResourceType.Auto,
        ),
      );
      if (response.secureUrl == null) {
        throw Exception('Failed to upload file to Cloudinary');
      }
      return response.secureUrl!;
    } catch (e) {
      throw Exception('Failed to upload to Cloudinary: $e');
    }
  }

  /// Retrieves all courses for a lecturer.
  Future<List<Course>> getCoursesForLecturer(String lecturerId) async {
    try {
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      QuerySnapshot querySnapshot =
          await _db
              .collection('courses')
              .where('lecturerId', isEqualTo: lecturerId)
              .orderBy('createdAt', descending: true)
              .get();
      return querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  /// Adds a module to a course.
  Future<void> addModule(
    String courseId,
    String title,
    String description,
    int order,
    String lecturerId,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (title.isEmpty) throw Exception('Title cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      if (courseDoc.get('lecturerId') != lecturerId) {
        throw Exception('Unauthorized: Lecturer does not own this course');
      }
      DocumentReference docRef = await _db
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .add({
            'courseId': courseId,
            'title': title,
            'description': description,
            'order': order,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await docRef.update({'id': docRef.id});

      // Log the interaction
      final interaction = Interaction(
        userId: lecturerId,
        action: 'add_module',
        targetId: docRef.id,
        courseId: courseId,
        details: 'Added module: $title to course: $courseId',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
    } catch (e) {
      throw Exception('Failed to add module: $e');
    }
  }

  /// Retrieves modules for a course.
  Future<List<Module>> getModules(String courseId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      QuerySnapshot querySnapshot =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .orderBy('order')
              .get();
      return querySnapshot.docs
          .map((doc) => Module.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get modules: $e');
    }
  }

  /// Adds a lesson to a module.
  Future<void> addLesson(
    String courseId,
    String moduleId,
    String title,
    String description,
    int order,
    String lecturerId,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (moduleId.isEmpty) throw Exception('Module ID cannot be empty');
      if (title.isEmpty) throw Exception('Title cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      if (courseDoc.get('lecturerId') != lecturerId) {
        throw Exception('Unauthorized: Lecturer does not own this course');
      }
      final moduleDoc =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .get();
      if (!moduleDoc.exists) throw Exception('Module not found: $moduleId');
      DocumentReference docRef = await _db
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('lessons')
          .add({
            'courseId': courseId,
            'moduleId': moduleId,
            'title': title,
            'description': description,
            'order': order,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await docRef.update({'id': docRef.id});

      // Log the interaction
      final interaction = Interaction(
        userId: lecturerId,
        action: 'add_lesson',
        targetId: docRef.id,
        courseId: courseId,
        details: 'Added lesson: $title to module: $moduleId',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
    } catch (e) {
      throw Exception('Failed to add lesson: $e');
    }
  }

  /// Retrieves lessons for a module.
  Future<List<Lesson>> getLessons(String courseId, String moduleId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (moduleId.isEmpty) throw Exception('Module ID cannot be empty');
      QuerySnapshot querySnapshot =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('lessons')
              .orderBy('order')
              .get();
      return querySnapshot.docs
          .map((doc) => Lesson.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get lessons: $e');
    }
  }

  /// Adds a unit to a lesson.
  Future<void> addUnit(
    String courseId,
    String moduleId,
    String lessonId,
    String title,
    String type,
    String url,
    String description,
    int order,
    String lecturerId,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (moduleId.isEmpty) throw Exception('Module ID cannot be empty');
      if (lessonId.isEmpty) throw Exception('Lesson ID cannot be empty');
      if (title.isEmpty) throw Exception('Title cannot be empty');
      if (type.isEmpty) throw Exception('Type cannot be empty');
      if (url.isEmpty) throw Exception('URL cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      if (!['video', 'pdf', 'image', 'text'].contains(type)) {
        throw Exception('Invalid content type: $type');
      }
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      if (courseDoc.get('lecturerId') != lecturerId) {
        throw Exception('Unauthorized: Lecturer does not own this course');
      }
      final moduleDoc =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .get();
      if (!moduleDoc.exists) throw Exception('Module not found: $moduleId');
      final lessonDoc =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('lessons')
              .doc(lessonId)
              .get();
      if (!lessonDoc.exists) throw Exception('Lesson not found: $lessonId');
      DocumentReference docRef = await _db
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('lessons')
          .doc(lessonId)
          .collection('units')
          .add({
            'courseId': courseId,
            'moduleId': moduleId,
            'lessonId': lessonId,
            'title': title,
            'type': type,
            'url': url,
            'description': description,
            'order': order,
            'createdAt': FieldValue.serverTimestamp(),
          });
      await docRef.update({'id': docRef.id});

      // Log the interaction
      final interaction = Interaction(
        userId: lecturerId,
        action: 'add_unit',
        targetId: docRef.id,
        courseId: courseId,
        details: 'Added $type unit: $title to lesson: $lessonId',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
    } catch (e) {
      throw Exception('Failed to add unit: $e');
    }
  }

  /// Retrieves units for a lesson.
  Future<List<Unit>> getUnits(
    String courseId,
    String moduleId,
    String lessonId,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (moduleId.isEmpty) throw Exception('Module ID cannot be empty');
      if (lessonId.isEmpty) throw Exception('Lesson ID cannot be empty');
      QuerySnapshot querySnapshot =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('lessons')
              .doc(lessonId)
              .collection('units')
              .orderBy('order')
              .get();
      return querySnapshot.docs
          .map((doc) => Unit.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get units: $e');
    }
  }

  /// Deletes a unit from a lesson.
  Future<void> deleteUnit(
    String courseId,
    String moduleId,
    String lessonId,
    String unitId,
    String lecturerId,
  ) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      if (moduleId.isEmpty) throw Exception('Module ID cannot be empty');
      if (lessonId.isEmpty) throw Exception('Lesson ID cannot be empty');
      if (unitId.isEmpty) throw Exception('Unit ID cannot be empty');
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      final courseDoc = await _db.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Course not found: $courseId');
      if (courseDoc.get('lecturerId') != lecturerId) {
        throw Exception('Unauthorized: Lecturer does not own this course');
      }
      final unitDoc =
          await _db
              .collection('courses')
              .doc(courseId)
              .collection('modules')
              .doc(moduleId)
              .collection('lessons')
              .doc(lessonId)
              .collection('units')
              .doc(unitId)
              .get();
      if (!unitDoc.exists) throw Exception('Unit not found: $unitId');
      final unitData = unitDoc.data() as Map<String, dynamic>;
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .collection('lessons')
          .doc(lessonId)
          .collection('units')
          .doc(unitId)
          .delete();

      // Log the interaction
      final interaction = Interaction(
        userId: lecturerId,
        action: 'delete_unit',
        targetId: unitId,
        courseId: courseId,
        details:
            'Deleted ${unitData['type']} unit: ${unitData['title']} from lesson: $lessonId',
        timestamp: Timestamp.now(),
      );
      await logInteraction(interaction);
    } catch (e) {
      throw Exception('Failed to delete unit: $e');
    }
  }

  /// Logs an interaction to the interactions collection.
  Future<void> logInteraction(Interaction interaction) async {
    try {
      if (interaction.userId.isEmpty)
        throw Exception('User ID cannot be empty');
      if (interaction.action.isEmpty) throw Exception('Action cannot be empty');
      await _db.collection('interactions').add(interaction.toMap());
    } catch (e) {
      throw Exception('Failed to log interaction: $e');
    }
  }

  /// Retrieves interactions for a user, skipping malformed documents, and fetches user names.
  Future<List<Interaction>> getInteractions(String userId) async {
    try {
      if (userId.isEmpty) throw Exception('User ID cannot be empty');
      debugPrint('Fetching interactions for user: $userId');
      QuerySnapshot querySnapshot =
          await _db
              .collection('interactions')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

      debugPrint('Found ${querySnapshot.docs.length} interaction documents');
      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<Interaction> interactions = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('Processing interaction document ${doc.id}: $data');
          if (data['userId'] is String &&
              data['action'] is String &&
              data['timestamp'] is Timestamp) {
            // Fetch admin name
            String? adminName;
            final adminDoc =
                await _db.collection('users').doc(data['userId']).get();
            if (adminDoc.exists) {
              adminName =
                  adminDoc.data()?['email']?.split('@')[0] ?? 'Unknown Admin';
            }

            // Fetch target user name if targetId exists
            String? targetName;
            if (data['targetId'] != null) {
              final targetDoc =
                  await _db.collection('users').doc(data['targetId']).get();
              if (targetDoc.exists) {
                targetName =
                    targetDoc.data()?['email']?.split('@')[0] ?? 'Unknown User';
              }
            }

            // Create Interaction with names
            interactions.add(
              Interaction(
                userId: data['userId'],
                action: data['action'],
                targetId: data['targetId'],
                details: data['details'],
                courseId: data['courseId'],
                timestamp: data['timestamp'],
                adminName: adminName,
                targetName: targetName,
              ),
            );
          } else {
            debugPrint(
              'Skipping malformed interaction document: ${doc.id} - Missing required fields',
            );
          }
        } catch (e) {
          debugPrint('Error parsing interaction document ${doc.id}: $e');
        }
      }
      return interactions;
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        debugPrint(
          'Index required for query on userId and timestamp. Please create the index via the Firebase Console.',
        );
        throw Exception(
          'Failed to get interactions: The query requires an index. Please create it in the Firebase Console at https://console.firebase.google.com/project/al-learn-db/firestore/indexes.',
        );
      }
      debugPrint('Failed to get interactions for user $userId: $e');
      rethrow;
    }
  }

  /// Retrieves all courses.
  Future<List<Course>> getCourses() async {
    try {
      QuerySnapshot querySnapshot =
          await _db
              .collection('courses')
              .orderBy('createdAt', descending: true)
              .get();
      return querySnapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  /// Retrieves a single course by ID.
  Future<Course?> getCourse(String courseId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      DocumentSnapshot doc =
          await _db.collection('courses').doc(courseId).get();
      return doc.exists
          ? Course.fromMap(doc.data() as Map<String, dynamic>)
          : null;
    } catch (e) {
      throw Exception('Failed to get course: $e');
    }
  }

  /*
  /// Retrieves lectures for a course.
  Future<List<Lecture>> getLectures(String courseId) async {
    try {
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      QuerySnapshot querySnapshot = await _db
          .collection('courses')
          .doc(courseId)
          .collection('lectures')
          .orderBy('createdAt')
          .get();
      return querySnapshot.docs
          .map((doc) => Lecture.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get lectures: $e');
    }
  }
  */
  /*
  /// Retrieves a single lecture by ID.
  Future<Lecture?> getLecture(String lectureId) async {
    try {
      if (lectureId.isEmpty) throw Exception('Lecture ID cannot be empty');
      DocumentSnapshot doc =
          await _db.collection('lectures').doc(lectureId).get();
      return doc.exists
          ? Lecture.fromMap(doc.data() as Map<String, dynamic>)
          : null;
    } catch (e) {
      throw Exception('Failed to get lecture: $e');
    }
  }

  /// Retrieves a single quiz by ID.
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      if (quizId.isEmpty) throw Exception('Quiz ID cannot be empty');
      DocumentSnapshot doc = await _db.collection('quizzes').doc(quizId).get();
      return doc.exists
          ? Quiz.fromMap(doc.data() as Map<String, dynamic>)
          : null;
    } catch (e) {
      throw Exception('Failed to get quiz: $e');
    }
  }

  /// Retrieves all lecturers.
  Future<List<Lecturer>> getLecturers() async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'lecturer')
          .get();
      return querySnapshot.docs
          .map((doc) => Lecturer.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get lecturers: $e');
    }
  }

  /// Retrieves a single lecturer by ID.
  Future<Lecturer?> getLecturer(String lecturerId) async {
    try {
      if (lecturerId.isEmpty) throw Exception('Lecturer ID cannot be empty');
      DocumentSnapshot doc =
          await _db.collection('users').doc(lecturerId).get();
      return doc.exists && doc.get('role') == 'lecturer'
          ? Lecturer.fromMap(doc.data() as Map<String, dynamic>)
          : null;
    } catch (e) {
      throw Exception('Failed to get lecturer: $e');
    }
  }
*/
  /// Saves user progress for a course.
  Future<void> saveUserProgress(
    String userId,
    String courseId,
    Map<String, int> lectureProgress,
    double quizScore,
  ) async {
    try {
      if (userId.isEmpty) throw Exception('User ID cannot be empty');
      if (courseId.isEmpty) throw Exception('Course ID cannot be empty');
      await _db.collection('user_progress').doc(userId).set({
        'userId': userId,
        'courseId': courseId,
        'lectureProgress': lectureProgress,
        'quizScore': quizScore,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user progress: $e');
    }
  }

  /// Retrieves user progress.
  Future<Map<String, dynamic>?> getUserProgress(String userId) async {
    try {
      if (userId.isEmpty) throw Exception('User ID cannot be empty');
      DocumentSnapshot doc =
          await _db.collection('user_progress').doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }

  /// Retrieves recently viewed courses for a user.
  Future<List<Course>> getRecentlyViewedCourses(String userId) async {
    try {
      if (userId.isEmpty) throw Exception('User ID cannot be empty');
      QuerySnapshot querySnapshot =
          await _db
              .collection('interactions')
              .where('userId', isEqualTo: userId)
              .where('action', isEqualTo: 'view_course')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();
      List<String> courseIds =
          querySnapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['courseId'] as String,
              )
              .toList();
      List<Course> courses = [];
      for (String courseId in courseIds) {
        Course? course = await getCourse(courseId);
        if (course != null) courses.add(course);
      }
      return courses;
    } catch (e) {
      throw Exception('Failed to get recently viewed courses: $e');
    }
  }

  /// Initializes Firestore with sample data (optional, for testing).
  Future<void> initializeCollections({bool force = false}) async {
    if (!force) return;
    try {
      // Initialize interactions collection
      await initializeInteractionsCollection();

      // Initialize courses
      QuerySnapshot coursesSnapshot =
          await _db.collection('courses').limit(1).get();
      if (coursesSnapshot.docs.isEmpty) {
        await _db.collection('courses').doc('course1').set({
          'id': 'course1',
          'title': 'Introduction to AI',
          'description': 'Learn the basics of Artificial Intelligence',
          'lecturerId': 'sample_lecturer',
          'token': 'sample_token',
          'category': 'Popular',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _db.collection('courses').doc('course2').set({
          'id': 'course2',
          'title': 'Advanced Machine Learning',
          'description': 'Deep dive into ML techniques',
          'lecturerId': 'sample_lecturer',
          'token': 'sample_token',
          'category': 'New',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Initialize lectures
      QuerySnapshot lecturesSnapshot =
          await _db.collection('lectures').limit(1).get();
      if (lecturesSnapshot.docs.isEmpty) {
        await _db.collection('lectures').doc('lecture1').set({
          'id': 'lecture1',
          'courseId': 'course1',
          'title': 'Lecture 1: AI Basics',
          'content': 'Introduction to the course and AI concepts',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Initialize quizzes
      QuerySnapshot quizzesSnapshot =
          await _db.collection('quizzes').limit(1).get();
      if (quizzesSnapshot.docs.isEmpty) {
        await _db.collection('quizzes').doc('quiz1').set({
          'id': 'quiz1',
          'courseId': 'course1',
          'title': 'AI Basics Quiz',
          'questions': [
            {
              'question': 'What does AI stand for?',
              'options': [
                'Artificial Intelligence',
                'Automated Integration',
                'Advanced Interface',
              ],
              'correct': 0,
            },
          ],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to initialize collections: $e');
    }
  }
}
