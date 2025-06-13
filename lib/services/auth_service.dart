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
          'role': role,
          'displayName': email.split('@')[0],
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final interaction = Interaction(
          userId: user.uid,
          action: 'sign_up',
          details: 'User signed up: $email',
          timestamp: Timestamp.now(),
        );
        await _firestoreService.logInteraction(interaction);
      }
      return user;
    } catch (e) {
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
      // Initialize a secondary Firebase app to avoid affecting the current session
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create user in the secondary app
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
          'role': role,
          'displayName': email.split('@')[0],
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Sign out from secondary app
        await secondaryAuth.signOut();
      }
      return user;
    } catch (e) {
      throw Exception('Create user failed: ${e.toString()}');
    } finally {
      // Ensure secondary app is deleted even if an error occurs
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (e) {
          print('Failed to delete secondary app: $e');
        }
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
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
      return false;
    }
  }

  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found. Please sign in.');
    }
    return user;
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
