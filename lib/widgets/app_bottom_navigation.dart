import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/friends_page.dart';
import '../pages/deadlines_page.dart';
import '../pages/profile_pages.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({super.key, required this.currentIndex});

  void _changePage(BuildContext context, int index) {
    if (index == currentIndex) return;

    final pages = <Widget>[
      const HomePage(),
      const FriendsPage(),
      const DeadlinesPage(),
      const ProfilePage(),
    ];

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => pages[index]));
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _changePage(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Amigos',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Prazos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
