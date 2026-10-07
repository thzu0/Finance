import 'package:finance/Onboard/onboarding_page.dart';
import 'package:finance/Screen/root.dart';
import 'package:finance/database/app_setting.dart';
import 'package:finance/database/seed_categories.dart';
import 'package:finance/security/app_lock_gate.dart';
import 'package:finance/services/background_worker.dart';
import 'package:finance/services/local_push_service.dart';
import 'package:finance/services/notification_scheduler.dart';
import 'package:finance/services/prefs_service.dart';
import 'package:finance/services/sms_sync_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSettings.instance.load();
  await seedCategoriesIfEmpty();

  await LocalPushService.instance.init();

  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    taskCheckBudget,
    taskCheckBudget,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  await NotificationScheduler.instance.syncAll();

  // ⬇️ چک کن کاربر قبلاً onboarding رو دیده یا نه
  final hasSeenOnboarding = await PrefsService.hasSeenOnboarding();

  runApp(MyApp(showOnboarding: !hasSeenOnboarding));
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;

  const MyApp({super.key, this.showOnboarding = true});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      home: widget.showOnboarding ? const OnboardingPage() : const RootPage(),
    );
  }
}
