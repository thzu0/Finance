import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/Screen/setting/notification_history_screen.dart';
import 'package:finance/database/app_setting.dart';

import 'package:finance/widget/build_home_page_container_widget.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:finance/widget/glowAvatar.dart';
import 'package:finance/widget/icon_appbar_widget.dart';

import 'package:flutter/material.dart';

import 'package:finance/services/notification_service.dart';
import 'package:page_transition/page_transition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _s = AppSettings.instance;
  late String _name = _s.get<String>('name', 'بدون نام');

  @override
  void initState() {
    super.initState();
    _s.changes.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _s.changes.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {
      _name = _s.get<String>('name', 'بدون نام');
    });
  }

  /// سلام بر اساس ساعت ایران (UTC+3:30 بدون DST)
  String _greeting() {
    final now = DateTime.now().toUtc();
    final iran = now.add(const Duration(hours: 3, minutes: 30));
    final h = iran.hour;

    if (h >= 5 && h < 12) return 'صبح بخیر';
    if (h >= 12 && h < 17) return 'ظهر بخیر';
    if (h >= 17 && h < 20) return 'عصر بخیر';
    return 'شب بخیر';
  }

  Future<void> _createTestNotification() async {
    final samples = [
      {
        'title': 'هشدار بودجه',
        'body': 'بودجه‌ی خورد و خوراک به ۸۵٪ رسید. حواست باشه!',
        'type': 'budget',
      },
      {
        'title': 'تراکنش جدید',
        'body': 'یه خرید ۲۵۰,۰۰۰ تومانی از بانک سامان ثبت شد.',
        'type': 'sms',
      },
      {
        'title': 'یادآوری',
        'body': 'امروز تراکنش‌هات رو ثبت کردی؟ یادت نره!',
        'type': 'daily',
      },
      {
        'title': 'گزارش هفتگی',
        'body':
            'این هفته ۱,۲۵۰,۰۰۰ تومان خرج کردی. نسبت به هفته‌ی قبل ۱۵٪ کمتر.',
        'type': 'weekly',
      },
      {
        'title': 'پیشنهاد هوشمند',
        'body':
            'اگه اشتراک‌های استفاده‌نشده‌ت رو لغو کنی، ماهانه ۲۰۰,۰۰۰ تومان صرفه‌جویی می‌کنی.',
        'type': 'tips',
      },
      {
        'title': 'خلاصه‌ی ماهانه',
        'body':
            'ماه گذشته ۴,۸۰۰,۰۰۰ تومان درآمد و ۳,۲۰۰,۰۰۰ تومان هزینه داشتی.',
        'type': 'monthly',
      },
    ];

    final s = samples[DateTime.now().millisecondsSinceEpoch % samples.length];

    await NotificationService.create(
      title: s['title']!,
      body: s['body']!,
      type: s['type']!,
    );

    if (!mounted) return;
    showGlassSnack(context, 'اعلان «${s['title']}» ساخته شد');
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccent,
        onPressed: _createTestNotification,
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
      backgroundColor: Constans.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              children: [
                _NotificationBell(),
                const SizedBox(width: 8),
                HeaderIconButton(icon: Icons.person_outline, onTap: () {}),
              ],
            ),
          ),
          const Spacer(),

          ///====================================
          ///Circle Avatar and Name of User
          ///====================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${_greeting()} ,',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 15,
                      color: Constans.textPrimary,
                    ),
                  ),
                  Text(
                    _name,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Constans.textPrimary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 15),
                child: GlowAvatar(
                  imageProvider: AssetImage('assets/images/profile.jfif'),
                ),
              ),
            ],
          ),
        ],
      ),

      ///=============================
      ///Content after App Bar
      ///=============================
      body: AppGlowBackground(
        child: SafeArea(child: BuildHomePage(size: size)),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.watchUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: const NotificationsHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none,
                color: Constans.textPrimary,
                size: 26,
              ),
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kDanger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
