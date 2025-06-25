import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/interaction.dart';
import '../services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      return credential.user;
    } catch (e) {
      print('Sign-in error: $e at ${DateTime.now()}');
      throw Exception('Sign-in failed: ${e.toString()}');
    }
  }

  Future<User?> signUp(
    String email,
    String password,
    String role, {
    required String username,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = credential.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'role': role.toLowerCase(), // Ensure lowercase
          'displayName': email.split('@')[0],
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final interaction = Interaction(
          userId: user.uid,
          action: 'sign_up',
          details: 'User signed up: $email, role: $role',
          timestamp: Timestamp.now(),
        );
        await _firestoreService.logInteraction(interaction);
      }
      return user;
    } catch (e) {
      print('Sign-up error: $e at ${DateTime.now()}');
      throw Exception('Sign-up failed: ${e.toString()}');
    }
  }

  Future<User?> createUserWithoutSignIn(
    String email,
    String password,
    String role, {
    required String username,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential credential = await secondaryAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
      User? user = credential.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': username,
          'role': role.toLowerCase(), // Ensure lowercase
          'displayName': email.split('@')[0],
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await secondaryAuth.signOut();
      }
      return user;
    } catch (e) {
      print('Create user error: $e at ${DateTime.now()}');
      throw Exception('Create user failed: ${e.toString()}');
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (e) {
          print('Failed to delete secondary app: $e at ${DateTime.now()}');
        }
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign-out error: $e at ${DateTime.now()}');
      throw Exception('Sign-out failed: ${e.toString()}');
    }
  }

  Future<bool> reAuthenticateAdmin(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } catch (e) {
      print('Re-authentication error: $e at ${DateTime.now()}');
      return false;
    }
  }

  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      print('No authenticated user found at ${DateTime.now()}.');
      throw Exception('No authenticated user found. Please sign in.');
    }
    return user;
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final role = data?['role'] as String?;
        print('Fetched role for UID $uid: $role at ${DateTime.now()}');
        return role?.toLowerCase(); // Return lowercase role
      }
      print('No user document found for UID: $uid at ${DateTime.now()}');
      return null;
    } catch (e) {
      print('Error getting role for UID $uid: $e at ${DateTime.now()}');
      throw Exception('Failed to get user role: $e');
    }
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
