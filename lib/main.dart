import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:products_catelogs/authentication/provider/authentication_provider.dart';
import 'package:products_catelogs/authentication/screens/splash_screen.dart';
// import 'package:products_catelogs/Home/screens/home_screen.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/dashboard/provider/staff_provider.dart';
import 'package:products_catelogs/dashboard/screen/dashboard_screen.dart';
import 'package:products_catelogs/firebase_options.dart';
import 'package:products_catelogs/products/provider/products_management_pro.dart';
import 'package:products_catelogs/settings/provider/setting_provider.dart';
import 'package:products_catelogs/staff_management/provider/provider.dart';
import 'package:products_catelogs/theme/theme.dart';
import 'package:products_catelogs/theme/themeprovider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create theme provider and wait for saved theme
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeFromPrefs();

  runApp(
    MultiProvider(
      providers: [
       
        ChangeNotifierProvider(create: (context) => UserProvider(),),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
          ChangeNotifierProvider(create: (_) => WhatsAppNumberProvider()..loadNumber()),
        ChangeNotifierProvider.value(value: themeProvider), // use preloaded provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RED ROSE STAFF',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // Dynamic theme
      home: const SplashScreen(),
    );
        },
      );
  }
}

