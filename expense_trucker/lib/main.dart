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
            enabled: true,
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
