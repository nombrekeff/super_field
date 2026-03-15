import 'package:flutter/material.dart';

import 'screens/mention_screen.dart';
import 'screens/hashtag_screen.dart';
import 'screens/formatting_screen.dart';
import 'screens/url_screen.dart';
import 'screens/form_field_screen.dart';
import 'screens/read_only_screen.dart';

void main() {
  runApp(const SuperFieldExampleApp());
}

class SuperFieldExampleApp extends StatelessWidget {
  const SuperFieldExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'super_field Examples',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _selectedIndex = 0;

  static const _tabs = [
    _TabItem(
      label: 'Mentions',
      icon: Icons.alternate_email,
      screen: MentionScreen(),
    ),
    _TabItem(
      label: 'Hashtags',
      icon: Icons.tag,
      screen: HashtagScreen(),
    ),
    _TabItem(
      label: 'Formatting',
      icon: Icons.format_bold,
      screen: FormattingScreen(),
    ),
    _TabItem(
      label: 'URLs',
      icon: Icons.link,
      screen: UrlScreen(),
    ),
    _TabItem(
      label: 'Form',
      icon: Icons.assignment,
      screen: FormFieldScreen(),
    ),
    _TabItem(
      label: 'Read-only',
      icon: Icons.visibility,
      screen: ReadOnlyScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('super_field Examples'),
        centerTitle: false,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final t in _tabs) t.screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.screen,
  });
}
