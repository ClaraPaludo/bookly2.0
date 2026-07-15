import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/friends_page.dart';
import '../pages/deadlines_page.dart';
import '../pages/profile_pages.dart';

class AppBottomNavigation extends StatelessWidget {
  // Índice da página atualmente selecionada.
  final int currentIndex;

  const AppBottomNavigation({super.key, required this.currentIndex});

  // Responsável por trocar de página ao clicar em um item da barra.
  void _changePage(BuildContext context, int index) {
    // Evita recarregar a mesma página.
    if (index == currentIndex) return;

    final pages = <Widget>[
      const HomePage(),
      const FriendsPage(),
      const DeadlinesPage(),
      const ProfilePage(),
    ];

    // Substitui a página atual pela página selecionada.
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => pages[index]));
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      // Define qual item ficará destacado.
      selectedIndex: currentIndex,
      // Chama o método para trocar de página
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
