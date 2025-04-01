import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:weni_ai/firebase_options.dart';
import 'package:weni_ai/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(WeniAi());
}

class WeniAi extends StatelessWidget {
  const WeniAi({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
