import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:products_catelogs/Home/screens/home_screen.dart';
import 'package:products_catelogs/categories/provider/category_provider.dart';
import 'package:products_catelogs/firebase_options.dart';
import 'package:products_catelogs/products/provider/products_management.dart';
import 'package:provider/provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
         ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider(),)
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
           scaffoldBackgroundColor: Colors.white,
           appBarTheme: AppBarTheme(backgroundColor: Colors.white)
    
        ),
        home: HomeScreen()
      ),
    );
  }
}

