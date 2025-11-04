// main.dart
import 'package:flutter/material.dart';
import 'package:gyro_viper/ui/pages/home_page.dart';
import 'package:gyro_viper/ui/pages/snake_game_page.dart';
import 'package:flutter/services.dart'; // 👈 required for SystemChrome

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gyro Vyper",
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      theme: ThemeData.dark(),

      routes: {
        "/": (context) => const HomePage(),
        "/game": (context) => const SnakeGamePage()
      },
    );
  }
}



