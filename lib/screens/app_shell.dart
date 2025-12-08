import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/global_mini_player.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/podcasts');
        break;
      case 2:
        context.go('/formations');
        break;
      case 3:
        context.go('/cotisation');
        break;
      case 4:
        context.go('/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioPlayerService>(context);
    final hasPodcast = audioService.currentPodcast != null;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini-player global
          const GlobalMiniPlayer(),
          // Barre de navigation
          BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFFF0000),
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.podcasts),
                label: 'Podcasts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Formations',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment),
                label: 'Cotisation',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
