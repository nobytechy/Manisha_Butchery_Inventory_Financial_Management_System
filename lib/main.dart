import 'package:flutter/material.dart';
import 'package:manisha_butchery/pages/splash_screen.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manisha Butchery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(
          0xFFF0F8FF,
        ), // Light blue background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A), // Dark blue
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
