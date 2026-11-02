import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'backup/auto_backup_scheduler.dart';
import 'crash/crash_log.dart';
import 'lock/app_navigator.dart';
import 'reminder/alarm_actions.dart';
import 'lock/lock_gate.dart';
import 'lock/lock_screen.dart' show lockIntroPending;
import 'providers/app_providers.dart';
import 'ui/app_shell.dart';
import 'ui/medicine_alarms_screen.dart' show alarmsRearmedProvider;
import 'ui/app_style.dart';
import 'ui/splash_screen.dart';
import 'ui/welcome_screen.dart';

bool skipIntro = false;

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await (await CrashLog.open()).install();
  await _initTimeZone();
  await _initNotifications();
  await AutoBackupScheduler.init();

  lockIntroPending = !skipIntro;
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
    onDidReceiveNotificationResponse: (r) {
      if (r.actionId != null) {
        handleAlarmAction(r);
        return;
      }
      final p = AlarmPayload.parse(r.payload);
      if (p != null) pendingRing.value = AlarmRing(p, r.id);
    },
    onDidReceiveBackgroundNotificationResponse: alarmActionBackground,
  );
  await _notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.deleteNotificationChannel(channelId: oldAlarmChannelId);
  // The phone opened the app from a ringing alarm: show it, and skip the intro.
  final launch = await _notificationsPlugin.getNotificationAppLaunchDetails();
  final opened = launch?.didNotificationLaunchApp == true ? launch!.notificationResponse : null;
  final p = AlarmPayload.parse(opened?.payload);
  if (p != null) {
    pendingRing.value = AlarmRing(p, opened!.id);
    skipIntro = true;
  }
}

class AmruthamApp extends ConsumerWidget {
  const AmruthamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(alarmsRearmedProvider);
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      builder: (context, child) => LockGate(child: child ?? const SizedBox.shrink()),
      title: 'Amrutham',
      locale: Locale(ref.watch(languageProvider)),
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('te')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: appTheme(),
      home: const SplashScreen(next: _AppGate()),
    );
  }
}

/// First launch shows the welcome screen; after that, straight to Home.
class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(welcomeSeenProvider).when(
      data: (seen) => seen ? const AppShell() : const WelcomeScreen(),
      loading: () => const Scaffold(),
      // If the flag can't be read, don't trap the user on the welcome screen.
      error: (_, _) => const AppShell(),
    );
  }
}
