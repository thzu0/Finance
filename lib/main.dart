import 'package:finance/Onboard/onboarding_page.dart';
import 'package:finance/database/app_setting.dart';
import 'package:finance/database/seed_categories.dart';
import 'package:finance/security/app_lock_gate.dart';
import 'package:finance/services/sms_sync_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await seedCategoriesIfEmpty();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // بعد از اولین فریم، اسکن اولیه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmsSyncService.sync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SmsSyncService.sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox()),
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en', 'US'), Locale('fa', 'IR')],
      localizationsDelegates: const [
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        textTheme: Theme.of(
          context,
        ).textTheme.apply(displayColor: Colors.white),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OnboardingPage(),
    );
  }
}
