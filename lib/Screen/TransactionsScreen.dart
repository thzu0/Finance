// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:flutter/material.dart';

//todos make search box glasses like and complete this page

class Transactionsscreen extends StatefulWidget {
  const Transactionsscreen({super.key});

  @override
  State<Transactionsscreen> createState() => _TransactionsscreenState();
}

class _TransactionsscreenState extends State<Transactionsscreen> {
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
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Text(
                  'تراکنش ها',
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
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        width: size.width * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: TextField(
                                  textAlign: TextAlign.start,
                                  showCursor: false,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.only(right: 5.0),
                                    hintText: 'جستجو...',
                                    border: InputBorder.none,
                                    // focusedBorder: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: Constans.textSecondary.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Lalezar',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18.0,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.search,
                              color: Constans.textPrimary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
