import 'package:flutter/material.dart';
import 'splash.dart';
import 'home.dart'; // Make sure to create home.dart

void main() => runApp(NearbyPinsApp());

class NearbyPinsApp extends StatelessWidget {
  const NearbyPinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearbyPins',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
