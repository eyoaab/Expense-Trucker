import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthRepository() {
    // Initialize GoogleSignIn with proper configuration based on platform
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId:
            "1077244688629-e4g0fvk2e45qo38k12d2n4ujs7h16njk.apps.googleusercontent.com",
        scopes: ['email', 'profile'],
      );
    } else {
      _googleSignIn = GoogleSignIn();
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      if (userCredential.user != null) {
        final user = UserModel.createNew(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(user.toJson());
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error in signUpWithEmailAndPassword: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error in signInWithEmailAndPassword: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        // For web platform, use signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // For mobile platforms, use the regular flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // User canceled the sign-in
          return null;
        }

        // Obtain auth details from Google sign-in
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Check if it's a new user and save to Firestore if it is
      if (userCredential != null &&
          userCredential.user != null &&
          (userCredential.additionalUserInfo?.isNewUser ?? false)) {
        final user = UserModel.createNew(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'User',
          photoUrl: userCredential.user!.photoURL,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(user.toJson());
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error in signInWithGoogle: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        // Only try to sign out of Google on non-web platforms
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          debugPrint('Error signing out of Google: $e');
          // Continue with Firebase signout even if Google signout fails
        }
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error in signOut: $e');
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error in sendPasswordResetEmail: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }

      return null;
    } catch (e) {
      debugPrint('Error in getUserData: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? photoUrl,
    String? preferredCurrency,
  }) async {
    try {
      // Get current user data
      final userData = await getUserData(uid);

      if (userData == null) {
        throw Exception('User data not found');
      }

      // Update user data
      final updatedUser = userData.copyWith(
        name: name,
        photoUrl: photoUrl,
        preferredCurrency: preferredCurrency,
      );

      // Save to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updatedUser.toJson());

      // Update Firebase Auth display name if provided
      if (name != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name);
      }

      // Update Firebase Auth photo URL if provided
      if (photoUrl != null && _auth.currentUser != null) {
        await _auth.currentUser!.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      debugPrint('Error in updateUserProfile: $e');
      rethrow;
    }
  }

  // Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
      }
    } catch (e) {
      debugPrint('Error in updatePassword: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        // Delete user data from Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .delete();

        // Delete user from Firebase Auth
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error in deleteAccount: $e');
      rethrow;
    }
  }
}
