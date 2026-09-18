import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:finance/Constans/constans.dart';

class CustomBottomNav extends StatefulWidget {
  const CustomBottomNav({super.key, this.onTap});

  final ValueChanged<int>? onTap;

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  int _selectedIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'خانه'),
    _NavItem(icon: Icons.sync_alt_rounded, label: 'تراکنش‌ها'),
    _NavItem(icon: Icons.pie_chart_rounded, label: 'بودجه'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'تحلیل'),
    _NavItem(icon: Icons.person_rounded, label: 'پروفایل'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 120.0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: 10,
              bottom: 10 + bottomInset,
            ),
            decoration: BoxDecoration(
              color: Constans.surface.withValues(alpha: 0.55),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (index) {
                final isSelected = index == _selectedIndex;
                final item = _items[index];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    widget.onTap?.call(index);
                  },
                  child: _NavItemWidget(item: item, isSelected: isSelected),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// یه آیتمِ نوار: فقط آیکون داخل پیلِ شیشه‌ایِ متحرک،
// متن همیشه بیرون از پیل، ثابت، فقط رنگش نرم تغییر می‌کنه
// ==========================================
class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;

  const _NavItemWidget({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // فقط آیکون داخل پیل - با انیمیشن نرم بین دو حالت
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Constans.electricBlue.withValues(alpha: 0.55)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Constans.electricBlue.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Icon(
                  item.icon,
                  size: isSelected ? 25 : 20,
                  color: isSelected ? Colors.white : Constans.textSecondary,
                ),
              ),
            ),
          ),
          // const SizedBox(height: 4),
          // متن - همیشه همینجا، بیرون از پیل، فقط رنگش نرم عوض می‌شه
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            style: TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 15,
              color: isSelected ? Constans.textPrimary : Constans.textSecondary,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
