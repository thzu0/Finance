import 'package:finance/Onboard/onboarding_page.dart';
import 'package:finance/database/seed_categories.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await seedCategoriesIfEmpty();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ← locale رو دیگه ست نمی‌کنیم (پیش‌فرض انگلیسی/سیستم می‌مونه)
      // که یعنی جهت‌گیری کل اپ دست‌نخورده باقی می‌مونه (همون که خودت
      // با Directionality دستی مدیریتش می‌کردی).
      // فقط این دلیگیت‌ها رو نگه می‌داریم تا وقتی صریحاً از فارسی
      // خواستیم (توی خودِ دیالوگ تاریخ)، در دسترس باشن.
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
