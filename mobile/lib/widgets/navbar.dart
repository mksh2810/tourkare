import 'package:flutter/material.dart';

import '../screens/homepage.dart';
import '../screens/my_trips.dart';
import '../screens/profile.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const new({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget destination;

    switch (index) {
      case 0:
        destination = const Homepage();
        break;
      case 1:
        destination = const MyTrips();
        break;
      case 2:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),

      backgroundColor: Colors.white,

      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,

      selectedFontSize: 12,
      unselectedFontSize: 12,

      type: BottomNavigationBarType.fixed,

      elevation: 10,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.luggage_outlined),
          activeIcon: Icon(Icons.luggage),
          label: 'My Trips',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2_outlined),
          activeIcon: Icon(Icons.person_2),
          label: 'Profile',
        ),
      ],
    );
  }
}
