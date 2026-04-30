import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'providers/phonogram_provider.dart';
import 'package:provider/provider.dart';
import 'screens/phonograms_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/settings_screen.dart';
import 'services/rating_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[App] Starting Phonograms app...');
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  debugPrint('[App] SharedPreferences loaded');
  runApp(
    ChangeNotifierProvider(
      create: (_) => PhonogramProvider(prefs),
      child: const PhonogramsApp(),
    ),
  );
}

class PhonogramsApp extends StatelessWidget {
  const PhonogramsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phonograms',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    RatingService.onAppOpen();
  }

  final List<Widget> _screens = const [
    PhonogramsScreen(),
    FlashcardsScreen(),
    QuizScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          debugPrint('[Nav] Tab tapped: $index');
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Phonograms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style_rounded),
            label: 'Flashcards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
