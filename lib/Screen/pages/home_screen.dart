import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/database/app_setting.dart';

import 'package:finance/widget/build_home_page_container_widget.dart';

import 'package:finance/widget/glowAvatar.dart';
import 'package:finance/widget/icon_appbar_widget.dart';

import 'package:flutter/material.dart';

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
            child: Row(
              children: [
                HeaderIconButton(
                  icon: Icons.notifications_none,
                  onTap: () {},
                  showBadge: true,
                ),
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
