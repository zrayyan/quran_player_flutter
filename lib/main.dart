import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/database_service.dart';
import 'utils/logger.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QuranPlayerApp());
}

class QuranPlayerApp extends StatelessWidget {
  const QuranPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (context) => Logger(),
        ),
        Provider(
          create: (context) => DatabaseService(
            dbPath: 'assets/quran-alafasy.db',
            logger: context.read<Logger>(),
          ),
        ),
        Provider(
          create: (context) => AudioService(
            logger: context.read<Logger>(),
            onError: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Quran Player',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
