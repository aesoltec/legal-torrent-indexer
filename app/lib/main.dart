import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LegalTorrentApp());
}

class LegalTorrentApp extends StatelessWidget {
  const LegalTorrentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legal Torrent Indexer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
