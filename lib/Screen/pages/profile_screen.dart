import 'package:finance/Constans/constans.dart';

import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/Screen/setting/about_us_screen.dart';
import 'package:finance/Screen/setting/account_security_screen.dart';
import 'package:finance/Screen/setting/app_setting.dart';
import 'package:finance/Screen/setting/credit_card_screen.dart';
import 'package:finance/Screen/setting/help_support_screen.dart';
import 'package:finance/Screen/setting/language_screen.dart';
import 'package:finance/Screen/setting/notification_screen.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class _ProfileOption {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class Profilescreen extends StatelessWidget {
  final String name;
  final String email;

  // برای عکس پروفایل: AssetImage('assets/images/avatar.png') یا NetworkImage(...)
  final ImageProvider? avatar;

  const Profilescreen({
    super.key,
    this.name = 'امیر',
    this.email = 'amir@email.com',
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final options = <_ProfileOption>[
      _ProfileOption(
        icon: Icons.shield_outlined,
        title: 'حساب کاربری و امنیت',
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: Accountsecurityscreen(),
            ),
          );
        },
      ),
      _ProfileOption(
        icon: Icons.notifications_none,
        title: 'اعلان‌ها',
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: Notificationsscreen(),
            ),
          );
        },
      ),
      _ProfileOption(
        icon: Icons.credit_card,
        title: 'کارت ها ',
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: CreditCardScreen(),
            ),
          );
        },
      ),
      _ProfileOption(
        icon: Icons.language,
        title: 'زبان',
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: Languagescreen(),
            ),
          );
        },
      ),
      _ProfileOption(
        icon: Icons.help_outline,
        title: 'راهنما و پشتیبانی',
        onTap: () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: Helpsupportscreen(),
            ),
          );
        },
      ),
      _ProfileOption(
        icon: Icons.info_outline,
        title: 'درباره ی ما',
        onTap: () {
          Navigator.push(
            context,
            PageTransition(type: PageTransitionType.fade, child: Aboutscreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Constans.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leadingWidth: 72,
        // آیکون تنظیمات بالا سمت چپ
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.fade,
                  child: Appsettingsscreen(),
                ),
              );
            },
            icon: Icon(
              Icons.settings_outlined,
              color: Constans.textPrimary,
              size: 28,
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Text(
                  'پروفایل',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Constans.textPrimary,
                    fontFamily: 'Lalezar',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppGlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  // اگه محتوا رفت زیر تیتر، این خط رو از کامنت دربیار:
                  // const SizedBox(height: 80),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildOptionsCard(options),
                  // فاصله برای اینکه زیر بتم‌نویگیشن نره
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── عکس + اسم + ایمیل ─────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // عکس پروفایل با حلقه‌ی آبی
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4C7DFF), Color(0xFF7C5CFF)],
              ),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF0B1B4A),
              backgroundImage: avatar,
              child: avatar == null
                  ? Icon(Icons.person, size: 40, color: Constans.textSecondary)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Lalezar',
                    fontSize: 30,
                    color: Constans.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    color: Constans.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── کارت گزینه‌ها ─────────────
  Widget _buildOptionsCard(List<_ProfileOption> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassBox(
        padding: const EdgeInsets.symmetric(),
        child: Column(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: options[i].onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          options[i].icon,
                          color: Constans.textSecondary,
                          size: 26,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            options[i].title,
                            style: TextStyle(
                              fontFamily: 'Lalezar',
                              fontSize: 18,
                              color: Constans.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Constans.textSecondary,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i != options.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 18,
                  endIndent: 18,
                  color: const Color(0xFF4C7DFF).withValues(alpha: 0.18),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
