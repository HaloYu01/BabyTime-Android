import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/baby_provider.dart';
import 'providers/diet_provider.dart';
import 'providers/feeding_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/growth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sleep_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  final baby = BabyProvider();
  await baby.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: baby),
        ChangeNotifierProxyProvider<SettingsProvider, SleepProvider>(
          create: (_) => SleepProvider(),
          update: (_, settings, sleep) => sleep!..updateSettings(settings),
        ),
        ChangeNotifierProxyProvider3<SettingsProvider, BabyProvider,
            SleepProvider, DietProvider>(
          create: (_) => DietProvider(),
          update: (_, settings, baby, sleep, diet) =>
              diet!..updateDeps(settings, baby, sleep),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, GalleryProvider>(
          create: (_) => GalleryProvider(),
          update: (_, settings, gallery) => gallery!..updateSettings(settings),
        ),
        ChangeNotifierProvider(create: (_) => GrowthProvider()),
        ChangeNotifierProvider(create: (_) => FeedingProvider()),
      ],
      child: const BabyTimeApp(),
    ),
  );
}