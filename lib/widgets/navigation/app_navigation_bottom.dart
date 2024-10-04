import 'package:flutter/material.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';

class AppNavigationBottom extends StatefulWidget {
  final int initialIndex;

  const AppNavigationBottom({super.key, this.initialIndex = 0});

  @override
  State<AppNavigationBottom> createState() => _AppNavigationBottomState();
}

class _AppNavigationBottomState extends State<AppNavigationBottom> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex >= 0) {
      _currentIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: false,
      showSelectedLabels: false,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      items: AppNavigation.destinations
          .map(
            (x) => BottomNavigationBarItem(
              icon: x.icon,
              label: x.label,
            ),
          )
          .toList(),
      onTap: (idx) {
        setState(() => _currentIndex = idx);
        AppRouter.instance.goNamed(AppNavigation.destinations[idx].page);
      },
    );
  }
}
