import 'package:flutter/material.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import 'screens/dashboard_screen.dart';

class InvestmentManagerApp extends StatelessWidget {
  const InvestmentManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investment Manager',
      theme: RummelBlueTheme.light(),
      darkTheme: RummelBlueTheme.dark(),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
