// import 'dart:developer';
// import 'dart:io' show Platform;
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';

// import 'core/providers/theme_provider.dart';
// import 'features/auth/providers/auth_provider.dart';
// import 'core/providers/preferences_provider.dart';
// import 'features/expenses/providers/budget_provider.dart';
// import 'features/expenses/providers/category_provider.dart';
// import 'features/expenses/providers/expense_provider.dart';
// import 'core/theme/app_theme.dart';
// import 'features/auth/screens/splash_screen.dart';
// import 'package:device_preview/device_preview.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const AppInitializer());
// }

// class AppInitializer extends StatelessWidget {
//   const AppInitializer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _initializeFirebase(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           return const MyApp();
//         }

//         // Show loading screen while Firebase initializes with DevicePreview and themes
//         return DevicePreview(
//           enabled: true,
//           builder: (context) => MaterialApp(
//             useInheritedMediaQuery: true,
//             locale: DevicePreview.locale(context),
//             builder: DevicePreview.appBuilder,
//             title: 'Expense Tracker',
//             debugShowCheckedModeBanner: false,
//             theme: AppTheme.lightTheme(),
//             darkTheme: AppTheme.darkTheme(),
//             themeMode: ThemeMode.system,
//             home: Scaffold(
//               body: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // App logo
//                     Container(
//                       width: 100,
//                       height: 100,
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).colorScheme.primary,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: const Icon(
//                         Icons.account_balance_wallet,
//                         size: 50,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       'Expense Tracker',
//                       style:
//                           Theme.of(context).textTheme.headlineSmall?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                     ),
//                     const SizedBox(height: 24),
//                     CircularProgressIndicator(
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<FirebaseApp> _initializeFirebase() async {
//     FirebaseApp firebaseApp;

//     try {
//       // For web platform, we need to use different options
//       if (kIsWeb) {
//         firebaseApp = await Firebase.initializeApp(
//           options: const FirebaseOptions(
//               apiKey: "AIzaSyBBg2lY9C8cnxnwUJ8iE-KWXXLShyTgqtw",
//               authDomain: "expense-trucker-app.firebaseapp.com",
//               projectId: "expense-trucker-app",
//               storageBucket: "expense-trucker-app.appspot.com",
//               messagingSenderId: "1077244688629",
//               appId: "1:1077244688629:web:be7a95d1d00da2d09a70db",
//               measurementId: "G-EZCRZPNJ17"),
//         );
//       } else {
//         // For non-web platforms
//         firebaseApp = await Firebase.initializeApp(
//           options: const FirebaseOptions(
//               apiKey: "AIzaSyBBg2lY9C8cnxnwUJ8iE-KWXXLShyTgqtw",
//               authDomain: "expense-trucker-app.firebaseapp.com",
//               projectId: "expense-trucker-app",
//               storageBucket: "expense-trucker-app.appspot.com",
//               messagingSenderId: "1077244688629",
//               appId: "1:1077244688629:web:be7a95d1d00da2d09a70db",
//               measurementId: "G-EZCRZPNJ17"),
//         );
//       }

//       log("Firebase initialized successfully");
//       return firebaseApp;
//     } catch (e) {
//       log("Firebase initialization error: $e");
//       rethrow;
//     }
//   }
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => PreferencesProvider()),
//         ChangeNotifierProvider(create: (context) => ThemeProvider()),
//         ChangeNotifierProvider(create: (context) => AuthProvider()),
//         ChangeNotifierProvider(create: (context) => ExpenseProvider()),
//         ChangeNotifierProvider(create: (context) => BudgetProvider()),
//         ChangeNotifierProvider(create: (context) => CategoryProvider()),
//       ],
//       child: Consumer<ThemeProvider>(
//         builder: (context, themeProvider, _) {
//           return DevicePreview(
//             enabled: true,
//             builder: (context) => MaterialApp(
//               useInheritedMediaQuery: true,
//               locale: DevicePreview.locale(context),
//               builder: DevicePreview.appBuilder,
//               title: 'Expense Tracker',
//               debugShowCheckedModeBanner: false,
//               theme: AppTheme.lightTheme(),
//               darkTheme: AppTheme.darkTheme(),
//               themeMode: themeProvider.themeMode,
//               home: const SplashScreen(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/providers/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/providers/preferences_provider.dart';
import 'features/expenses/providers/budget_provider.dart';
import 'features/expenses/providers/category_provider.dart';
import 'features/expenses/providers/expense_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
              apiKey: "AIzaSyDekOHb35sGo7pymZJFUN5Hgy1md2Al_eA",
              authDomain: "expense-trucker-2c5ca.firebaseapp.com",
              projectId: "expense-trucker-2c5ca",
              storageBucket: "expense-trucker-2c5ca.firebasestorage.app",
              messagingSenderId: "933024527676",
              appId: "1:933024527676:web:54ee3012f88b828841da39",
              measurementId: "G-EZCRZPNJ17")
          : null, // Mobile platforms should auto-detect google-services.json
    );
    log("✅ Firebase initialized successfully");
  } catch (e) {
    log("❌ Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PreferencesProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ExpenseProvider()),
        ChangeNotifierProvider(create: (context) => BudgetProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return DevicePreview(
            enabled: false,
            builder: (context) => MaterialApp(
              useInheritedMediaQuery: true,
              locale: DevicePreview.locale(context),
              builder: DevicePreview.appBuilder,
              title: 'Expense Tracker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              themeMode: themeProvider.themeMode,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
