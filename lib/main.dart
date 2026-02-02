import 'package:flutter/material.dart';
import 'core/hive_setup.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive(); // Initialize Hive
  runApp(const FourRetailsApp());
}

class FourRetailsApp extends StatelessWidget {
  const FourRetailsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4Retails',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}