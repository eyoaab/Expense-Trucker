import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class NetworkUtils {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Check if device is connected to the internet
  static Future<bool> isConnected() async {
    try {
      return await InternetConnectionChecker().hasConnection;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }

  // Show a snackbar if no internet connection is available
  static void showNoInternetSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppConstants.internetConnectionError),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Retry a function with a check for internet connection
  static Future<T?> retryWithConnection<T>({
    required BuildContext context,
    required Future<T> Function() function,
    bool showError = true,
  }) async {
    final bool connected = await isConnected();

    if (!connected) {
      if (showError && context.mounted) {
        showNoInternetSnackBar(context);
      }
      return null;
    }

    try {
      return await function();
    } catch (e) {
      debugPrint('Error in function execution: $e');
      return null;
    }
  }

  /// Upload a profile image to Firebase Storage
  /// Returns the download URL of the uploaded image
  static Future<String> uploadProfileImage(
      String userId, File imageFile) async {
    // Create a reference to the location you want to upload to in firebase
    final fileName = path.basename(imageFile.path);
    final destination = 'profiles/$userId/$fileName';
    final ref = _storage.ref().child(destination);

    // Upload the file to firebase
    final uploadTask = ref.putFile(imageFile);

    // Wait until the file is uploaded then return the download URL
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload a profile image from web to Firebase Storage
  /// Returns the download URL of the uploaded image
  static Future<String> uploadProfileImageWeb(
      String userId, Uint8List imageData, String fileName) async {
    // Create a reference to the location you want to upload to in firebase
    final destination = 'profiles/$userId/$fileName';
    final ref = _storage.ref().child(destination);

    // Upload the file to firebase
    final uploadTask = ref.putData(
      imageData,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Wait until the file is uploaded then return the download URL
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload a receipt image to Firebase Storage
  /// Returns the download URL of the uploaded image
  static Future<String> uploadReceiptImage(
      String userId, String expenseId, File imageFile) async {
    // Create a reference to the location you want to upload to in firebase
    final fileName = path.basename(imageFile.path);
    final destination = 'receipts/$userId/$expenseId/$fileName';
    final ref = _storage.ref().child(destination);

    // Upload the file to firebase
    final uploadTask = ref.putFile(imageFile);

    // Wait until the file is uploaded then return the download URL
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete an image from Firebase Storage by URL
  static Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      // Extract the path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Handle any errors
      rethrow;
    }
  }
}
