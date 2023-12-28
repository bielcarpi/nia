import 'package:flutter/material.dart';
import '../../features/core/controllers/home_controller.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final HomeController controller;

  CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.controller,
  });

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
      currentIndex: selectedIndex,
      onTap: (index) => controller.selectTab(context, index),
    );
  }
}
