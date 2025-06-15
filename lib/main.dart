
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'authChecker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kzfgijyfzjamvcglkxgu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt6ZmdpanlmemphbXZjZ2xreGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MzE0OTYsImV4cCI6MjA2NTUwNzQ5Nn0.CEf_T5YkDr04GYDu8Can5LCTsMY9HAM4mmvfmv4XgZo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthChecker(),
      debugShowCheckedModeBanner: false,
    );
  }
}

