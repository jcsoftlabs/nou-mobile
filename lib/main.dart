import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/providers/auth_provider.dart';
import 'services/audio_player_service.dart';
import 'router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'NOU App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router(authProvider),
          );
        },
      ),
    );
  }
}
