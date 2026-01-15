import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this
import 'package:firebase_auth/firebase_auth.dart'; // Add this
import 'package:shared_preferences/shared_preferences.dart'; // Add this
import 'firebase_options.dart'; // Add this
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // Add this
import 'services/auth_service.dart'; // Add this
import 'models/meal.dart';
import 'services/api_service.dart';

// Update main to be async for Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TDKFoodApp());
}

class TDKFoodApp extends StatefulWidget {
  const TDKFoodApp({super.key});

  @override
  State<TDKFoodApp> createState() => _TDKFoodAppState();
}

class _TDKFoodAppState extends State<TDKFoodApp> {
  bool isIcelandic = true;
  final ValueNotifier<List<Meal>> menuNotifier = ValueNotifier<List<Meal>>([]);
  final ValueNotifier<List<String>> orderedDatesNotifier =
      ValueNotifier<List<String>>([]);
  bool isLoading = false;
  String? _lastUserId;
  String closingTime = "09:30"; // Default

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isIcelandic = prefs.getBool('isIcelandic') ?? true;
      });
    }
  }

  Future<void> _toggleLanguage() async {
    setState(() => isIcelandic = !isIcelandic);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isIcelandic', isIcelandic);
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Both requests fire at the same time
      final results = await Future.wait([
        ApiService.fetchMenu(),
        ApiService.fetchOrderedDates(),
      ]);

      final menuData = results[0] as Map<String, dynamic>;
      menuNotifier.value = menuData['meals'] as List<Meal>;
      
      // Update closing time
      if (mounted) {
        setState(() {
          closingTime = menuData['closingTime'] as String;
        });
      }

      orderedDatesNotifier.value = results[1] as List<String>;
    } catch (e) {
      debugPrint("Startup Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: AuthService().user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            // Check if user changed
            if (_lastUserId != user.uid) {
              _lastUserId = user.uid;
              // Clear old data and reload
              Future.microtask(() {
                menuNotifier.value = [];
                orderedDatesNotifier.value = [];
                _loadInitialData();
              });
            } else if (menuNotifier.value.isEmpty && !isLoading) {
              // Same user but no data (e.g. app restart with persisted auth)
              Future.microtask(() => _loadInitialData());
            }

            return HomeScreen(
              isIcelandic: isIcelandic,
              onToggleLanguage: _toggleLanguage,
              menuNotifier: menuNotifier,
              orderedDatesNotifier: orderedDatesNotifier,
              isLoading: isLoading,
              onRefresh: _loadInitialData,
              closingTime: closingTime,
            );
          }

          // User logged out
          _lastUserId = null;
          // Clear data if present
          if (menuNotifier.value.isNotEmpty ||
              orderedDatesNotifier.value.isNotEmpty) {
            Future.microtask(() {
              menuNotifier.value = [];
              orderedDatesNotifier.value = [];
            });
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
