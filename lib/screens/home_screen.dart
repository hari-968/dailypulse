import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'movies/movies_screen.dart';
import 'bookmarks/bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MoviesScreen(),
    BookmarksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) {
          final fadeAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          final slideAnim = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(fadeAnim);
          return FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(position: slideAnim, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.divider,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.movie_outlined),
              selectedIcon: Icon(Icons.movie_rounded),
              label: 'Movies',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border_rounded),
              selectedIcon: Icon(Icons.bookmark_rounded),
              label: 'Bookmarks',
            ),
          ],
        ),
      ),
    );
  }
}
