import 'package:finance/Constans/constans.dart';
import 'package:finance/services/prefs_service.dart';
import 'package:finance/Screen/root.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  ///============================================
  /// FINISH ONBOARDING
  ///============================================
  Future<void> _finishOnboarding() async {
    // ذخیره کن که کاربر دیده
    await PrefsService.setOnboardingSeen();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageTransition(child: const RootPage(), type: PageTransitionType.fade),
    );
  }

  ///============================================
  /// CREATE INDICATORS
  ///============================================
  Widget _indicators(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(microseconds: 0),
      height: 10.0,
      width: isActive ? 20.0 : 8.0,
      margin: const EdgeInsets.only(right: 5.0),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4682FF) : const Color(0xFF263A70),
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }

  ///============================================
  /// WORK OF INDICATORS
  ///============================================
  List<Widget> _buildIndicator() {
    List<Widget> indicators = [];

    for (int i = 0; i < 4; i++) {
      if (currentIndex == i) {
        indicators.add(_indicators(true));
      } else {
        indicators.add(_indicators(false));
      }
    }
    return indicators;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constans.background,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Constans.background,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                'رد کردن ',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PageView(
            onPageChanged: (int page) {
              setState(() {
                currentIndex = page;
              });
            },
            controller: _pageController,
            children: [
              CreatePage(
                image: 'assets/images/page_one.png',
                title: 'آینده مالی‌ات را بساز',
                description:
                    'درآمد و هزینه‌هایت را مدیریت کن و قدم‌به‌قدم به سمت یک آینده مالی بهتر حرکت کن',
              ),
              CreatePage(
                image: 'assets/images/page_two.png',
                title: 'همه‌چیز را تحت کنترل داشته باش',
                description:
                    'هزینه‌هایت را ببین، دسته‌بندی کن و بدان پولت دقیقاً کجا خرج می‌شود.',
              ),
              CreatePage(
                image: 'assets/images/page_three.png',
                title: 'برای هدف‌هایت پس‌انداز کن',
                description:
                    'هدف مالی تعیین کن، پیشرفتت را دنبال کن و با قدم‌های کوچک به رویاهایت نزدیک‌تر شو.',
              ),
              CreatePage(
                image: 'assets/images/page_four.png',
                title: 'پول تو، امنیت تو',
                description:
                    'اطلاعات مالی‌ات را امن نگه دار و با خیال راحت امور مالی روزمره‌ات را مدیریت کن',
              ),
            ],
          ),
          Positioned(
            bottom: 110.0,
            left: 40.0,
            child: Row(children: _buildIndicator()),
          ),
          Positioned(
            bottom: 90.0,
            right: 40.0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4682FF),
              ),
              child: IconButton(
                onPressed: () {
                  if (currentIndex < 3) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    _finishOnboarding();
                  }
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF263A70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///============================================
/// CREATE PAGE ONBOARD
///============================================
class CreatePage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const CreatePage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50.0, right: 50.0, bottom: 150.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Image.asset(
              image,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: Constans.textPrimary,
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            textAlign: TextAlign.center,
            description,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 21.0,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }
}
