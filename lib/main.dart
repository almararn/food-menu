import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'models/meal.dart';
import 'services/api_service.dart';

void main() => runApp(const TDKFoodApp());

class TDKFoodApp extends StatefulWidget {
  const TDKFoodApp({super.key});

  @override
  State<TDKFoodApp> createState() => _TDKFoodAppState();
}

class _TDKFoodAppState extends State<TDKFoodApp> {
  bool isIcelandic = true;
  // CHANGE 1: Use a ValueNotifier instead of a List
  // This is a "Smart Container" that notifies listeners when contents change
  final ValueNotifier<List<Meal>> menuNotifier = ValueNotifier<List<Meal>>([]);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => isLoading = true);
    try {
      final meals = await ApiService.fetchMenu();
      // CHANGE 2: Update the Value inside the notifier
      // Everyone holding this notifier (like the screens) sees this update instantly
      menuNotifier.value = meals;

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: HomeScreen(
        isIcelandic: isIcelandic,
        onToggleLanguage: () => setState(() => isIcelandic = !isIcelandic),
        // CHANGE 3: Pass the Notifier, not the list
        menuNotifier: menuNotifier,
        isLoading: isLoading,
        onRefresh: _loadMenu,
      ),
    );
  }
}
