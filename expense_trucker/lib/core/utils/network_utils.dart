import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class NetworkUtils {
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
}
