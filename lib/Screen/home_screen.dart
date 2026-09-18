import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';

import 'package:finance/widget/build_home_page_container_widget.dart';
import 'package:finance/widget/custom_bottm_nav_widget.dart';

import 'package:finance/widget/glowAvatar.dart';
import 'package:finance/widget/icon_appbar_widget.dart';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          ///====================================
          ///
          ///====================================
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
                    'صبح بخیر ,',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 15,

                      color: Constans.textPrimary,
                    ),
                  ),
                  Text(
                    'امیرطاها',
                    textDirection: TextDirection.rtl,

                    style: TextStyle(
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
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
