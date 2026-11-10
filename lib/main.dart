import 'package:flutter/material.dart';

void main() {
  runApp(const LostFoundApp());
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Campus Lost & Found',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Campus Lost & Found')),
      ),
    );
  }
}
