import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/routing/app_routes.dart';


class CustomBottomNavigationBar extends StatefulWidget {
  final BuildContext context;
  const CustomBottomNavigationBar({super.key, required this.context});

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Get.offAllNamed(AppRoutes.PROFILE);
    } else if (index == 1) {
      Get.offAllNamed(AppRoutes.HOME);
    } else if (index == 2) {
      Get.offAllNamed(AppRoutes.TIMELINE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Timeline',
        ),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }
}
