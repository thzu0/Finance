import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/Screen/setting/notification_history_screen.dart';
import 'package:finance/database/app_setting.dart';

import 'package:finance/widget/build_home_page_container_widget.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:finance/widget/glowAvatar.dart';

import 'package:flutter/material.dart';

import 'package:finance/services/notification_service.dart';
import 'package:page_transition/page_transition.dart';

import 'package:finance/widget/app_tour.dart';
import 'package:finance/widget/tab_notifier.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'dart:io';
import 'package:finance/services/avatar_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _s = AppSettings.instance;
  late String _name = _s.get<String>('name', 'بدون نام');

  final _bellKey = GlobalKey();
  final _balanceKey = GlobalKey();
  final _actionsKey = GlobalKey();
  final _monthKey = GlobalKey();
  final _spendingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _s.changes.addListener(_onSettingsChanged);
    activeTab.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  @override
  void dispose() {
    _s.changes.removeListener(_onSettingsChanged);
    activeTab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (activeTab.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
    }
  }

  Future<void> _maybeStartTour() async {
    if (!mounted || activeTab.value != 0 || _s.tourSeen('home')) return;
    // صبر کن داده‌های خانه لود بشن و کارت‌ها ساخته بشن
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || activeTab.value != 0) return;

    AppTour.showOnce(
      context,
      page: 'home',
      seen: _s.tourSeen('home'),
      isMounted: () => mounted,
      markSeen: () => _s.setTourSeen('home'),
      steps: [
        TourStep(
          _bellKey,
          'اعلان‌ها',
          'هشدارهای بودجه و تراکنش‌های ثبت‌شده‌ی خودکار اینجا جمع می‌شن. عدد قرمز تعداد خوانده‌نشده‌هاست.',
        ),
        TourStep(
          _balanceKey,
          'موجودی کل',
          'مجموع موجودی‌ت و تغییرش نسبت به اول ماه. با آیکون چشم می‌تونی مبلغ‌ها رو مخفی کنی.',
        ),
        TourStep(
          _actionsKey,
          'ثبت سریع',
          'از اینجا بودجه تعیین کن یا هزینه و درآمد جدید ثبت کن.',
        ),
        TourStep(
          _monthKey,
          'خلاصه‌ی این ماه',
          'درآمد، هزینه و پس‌انداز ماه جاری، همراه با مقایسه با ماه قبل.',
          align: ContentAlign.top,
        ),
        TourStep(
          _spendingKey,
          'بررسی هزینه‌ها',
          'نمودار نشون می‌ده بیشتر پولت کجا خرج شده.',
          align: ContentAlign.top,
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
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
            child: Row(children: [_NotificationBell(key: _bellKey)]),
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
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 15),
                child: AvatarService.path != null
                    ? GlowAvatar(
                        imageProvider: FileImage(File(AvatarService.path!)),
                      )
                    : Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4C7DFF), Color(0xFF7C5CFF)],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF0B1B4A),
                          child: Icon(
                            Icons.person,
                            size: 28,
                            color: Constans.textSecondary,
                          ),
                        ),
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
        child: SafeArea(
          child: BuildHomePage(
            size: size,
            balanceKey: _balanceKey,
            actionsKey: _actionsKey,
            monthKey: _monthKey,
            spendingKey: _spendingKey,
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({super.key});
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
