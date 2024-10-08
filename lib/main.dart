// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:qabas/screens/main_login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainLoginPage(),
      // ... other app configurations
    );
  }
}