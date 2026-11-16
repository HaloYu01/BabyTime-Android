import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'pages/main_shell.dart';

class BabyTimeApp extends StatelessWidget {
  const BabyTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyTime 育儿助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}