import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'services/storage_service.dart';
import 'providers/connection_provider.dart';
import 'providers/live_data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/schedules_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const GivLocalApp(),
    ),
  );
}

class GivLocalApp extends ConsumerStatefulWidget {
  const GivLocalApp({super.key});

  @override
  ConsumerState<GivLocalApp> createState() => _GivLocalAppState();
}

class _GivLocalAppState extends ConsumerState<GivLocalApp> {
  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    final api = ref.read(apiServiceProvider);
    await api.connect();
    ref.read(connectionStateProvider.notifier).state = api.connectionState;

    final storage = ref.read(storageServiceProvider);
    final serial = storage.inverterSerial;
    if (serial.isNotEmpty) {
      ref.read(liveDataProvider.notifier).startPolling(serial);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GivLocal',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    AnalyticsScreen(),
    SchedulesScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
