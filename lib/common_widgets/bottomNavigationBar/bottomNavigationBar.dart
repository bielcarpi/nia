import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/core/controllers/home_controller.dart';
import '../../features/core/views/home_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/timeline/views/timeline_screen.dart';


class CustomBottomNavigationBar extends StatefulWidget {
  final BuildContext context;
  CustomBottomNavigationBar({Key? key, required this.context}) : super(key: key);

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
      Get.offAll(() => ProfileScreen());
    } else if (index == 1) {
      Get.offAll(() => HomeScreen());
    } else if (index == 2) {
      Get.offAll(() => TimelineScreen());
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
