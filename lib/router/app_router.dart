import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/inscription_screen.dart';
import '../screens/home_screen.dart';
import '../screens/app_shell.dart';
import '../screens/podcast_screen.dart';
import '../screens/formations_list_screen.dart';
import '../screens/cotisation_screen.dart';
import '../screens/parrainage_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/don_screen.dart';
import '../screens/news_list_screen.dart';
import '../screens/annonces_screen.dart';

class AppRouter {
  static CustomTransitionPage _buildPage(Widget child) {
    return CustomTransitionPage(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;

        // Si on est sur le splash et que le chargement est terminé
        if (state.matchedLocation == '/') {
          if (isLoading) {
            return null; // Reste sur splash pendant le chargement
          }
          // Chargement terminé, rediriger selon l'état d'auth
          return isAuthenticated ? '/home' : '/welcome';
        }

        // Routes publiques (utiliser startsWith pour gérer d'éventuels sous-chemins)
        final location = state.matchedLocation;
        final isPublicRoute = location.startsWith('/welcome') ||
            location.startsWith('/login') ||
            location.startsWith('/register') ||
            location.startsWith('/forgot-password');

        // Si non authentifié et essaie d'accéder à une route protégée
        if (!isAuthenticated && !isPublicRoute) {
          return '/welcome';
        }

        // Si authentifié et sur une route publique, rediriger vers home
        // MAIS seulement si on n'est pas en train de charger (pour éviter la redirection pendant le login)
        if (isAuthenticated && isPublicRoute && !isLoading) {
          return '/home';
        }

        return null;
      },
      routes: [
        // Splash
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _buildPage(const SplashScreen()),
        ),

        // Welcome
        GoRoute(
          path: '/welcome',
          pageBuilder: (context, state) => _buildPage(const WelcomeScreen()),
        ),

        // Login
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => _buildPage(const LoginScreen()),
        ),

        // Register
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => _buildPage(const InscriptionScreen()),
        ),

        // Forgot Password
        GoRoute(
          path: '/forgot-password',
          pageBuilder: (context, state) => _buildPage(const ForgotPasswordScreen()),
        ),

        // Home (protégé)
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _buildPage(const AppShell(
            currentIndex: 0,
            child: HomeScreen(),
          )),
        ),

        // Podcasts (protégé)
        GoRoute(
          path: '/podcasts',
          pageBuilder: (context, state) => _buildPage(const AppShell(
            currentIndex: 1,
            child: PodcastScreen(),
          )),
        ),

        // Formations (protégé)
        GoRoute(
          path: '/formations',
          pageBuilder: (context, state) => _buildPage(const AppShell(
            currentIndex: 2,
            child: FormationsListScreen(),
          )),
        ),

        // Cotisation (protégé)
        GoRoute(
          path: '/cotisation',
          pageBuilder: (context, state) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final membreId = authProvider.currentMembre?.id ?? 1;

            return _buildPage(AppShell(
              currentIndex: 3,
              child: CotisationScreen(membreId: membreId),
            ));
          },
        ),

        // Profil (protégé)
        GoRoute(
          path: '/profil',
          pageBuilder: (context, state) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final membreId = authProvider.currentMembre?.id ?? 1;

            return _buildPage(AppShell(
              currentIndex: 4,
              child: ProfileScreen(membreId: membreId),
            ));
          },
        ),

        // Parrainage (protégé)
        GoRoute(
          path: '/parrainage',
          pageBuilder: (context, state) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final membreId = authProvider.currentMembre?.id ?? 1;
            final codeAdhesion = authProvider.currentMembre?.codeAdhesion ?? '';

            return _buildPage(AppShell(
              currentIndex: 0, // Accueil, car Parrainage n'est pas dans la bottom nav
              child: ParrainageScreen(
                membreId: membreId,
                codeAdhesion: codeAdhesion,
              ),
            ));
          },
        ),

        // Don (protégé)
        GoRoute(
          path: '/don',
          pageBuilder: (context, state) => _buildPage(const AppShell(
            currentIndex: 0,
            child: DonScreen(),
          )),
        ),

        // News (protégé)
        GoRoute(
          path: '/news',
          pageBuilder: (context, state) => _buildPage(const AppShell(
            currentIndex: 0,
            child: NewsListScreen(),
          )),
        ),

        // Annonces (protégé)
        GoRoute(
          path: '/annonces',
          pageBuilder: (context, state) => _buildPage(const AppShell(
            currentIndex: 0,
            child: AnnoncesScreen(),
          )),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Erreur: ${state.error}'),
        ),
      ),
    );
  }
}
