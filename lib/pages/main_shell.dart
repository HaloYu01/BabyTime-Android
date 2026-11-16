import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/nexio_glass.dart';
import 'diet/diet_page.dart';
import 'home/home_page.dart';
import 'settings/settings_page.dart';
import 'sleep/sleep_page.dart';
import 'tools/tools_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const NexioBackground(),
          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: [
                HomePage(onNavigate: _go),
                const SleepPage(),
                const DietPage(),
                const ToolsPage(),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: max(safeBottom + 2, 22),
            child: NexioBottomBar(
              selected: _index,
              onSelected: _go,
              onTrailingTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
              items: const [
                NexioBarItem(Icons.home_outlined, Icons.home, '首页'),
                NexioBarItem(Icons.bedtime_outlined, Icons.bedtime, '睡眠'),
                NexioBarItem(Icons.restaurant_outlined, Icons.restaurant, '饮食'),
                NexioBarItem(Icons.widgets_outlined, Icons.widgets, '工具'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}