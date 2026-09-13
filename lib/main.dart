import 'package:finance/Onboard/onboarding_page.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        textTheme: Theme.of(
          context,
        ).textTheme.apply(displayColor: Colors.white),
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OnboardingPage(),
    );
  }
}
