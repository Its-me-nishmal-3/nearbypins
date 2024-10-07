import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NearbyPins Home'),
      ),
      body: Center(
        child: Text(
          'Welcome to NearbyPins!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
