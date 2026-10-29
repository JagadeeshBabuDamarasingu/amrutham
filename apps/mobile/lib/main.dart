import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'providers/app_providers.dart';
import 'ui/home_screen.dart';
import 'ui/splash_screen.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initTimeZone();
  await _initNotifications();

  runApp(
    ProviderScope(
      overrides: [
        notificationsPluginProvider.overrideWithValue(_notificationsPlugin),
      ],
      child: const AmruthamApp(),
    ),
  );
}

/// Without setting the local location explicitly, `timezone`'s `tz.local`
/// defaults to UTC — reminders would silently fire at the wrong wall-clock
/// time for every user outside UTC. See pubspec.yaml's flutter_timezone note.
Future<void> _initTimeZone() async {
  tz_data.initializeTimeZones();
  final localTimezone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
}

Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const iosSettings = DarwinInitializationSettings();
  await _notificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
  );
}

class AmruthamApp extends StatelessWidget {
  const AmruthamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amrutham',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const SplashScreen(next: HomeScreen()),
    );
  }
}
