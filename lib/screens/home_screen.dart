import 'package:flutter/material.dart';
import 'day_selection_screen.dart';
import '../models/meal.dart';
import 'package:intl/intl.dart'; // Add this for date formatting

class HomeScreen extends StatelessWidget {
  final bool isIcelandic;
  final VoidCallback onToggleLanguage;
  final ValueNotifier<List<Meal>> menuNotifier;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const HomeScreen({
    super.key,
    required this.isIcelandic,
    required this.onToggleLanguage,
    required this.menuNotifier,
    required this.isLoading,
    required this.onRefresh,
  });

  // Helper function to calculate the date range string
  String _getWeekRange() {
    final meals = menuNotifier.value;
    if (meals.isEmpty) return "";

    // 1. Extract all fullDate strings and parse them to DateTime objects
    List<DateTime> dates = meals
        .map((m) => DateTime.tryParse(m.fullDate))
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return "";

    // 2. Find the earliest and latest dates
    dates.sort();
    DateTime first = dates.first;
    DateTime last = dates.last;

    // 3. Format them as DD.MM.YYYY
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    String range = "${formatter.format(first)} - ${formatter.format(last)}";

    return isIcelandic ? "Matseðill vikunnar\n$range" : "Weekly Menu $range";
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the check in a ValueListenableBuilder so it updates when the list changes
    return ValueListenableBuilder<List<Meal>>(
      valueListenable: menuNotifier,
      builder: (context, meals, child) {
        bool isMenuReady = !isLoading && meals.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.blueGrey.shade900,
            centerTitle: true,
            title: Text(
              'Order Food',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: onToggleLanguage,
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: Text(
                    isIcelandic ? "🇬🇧 ENG" : "🇮🇸 ISL",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBigButton(
                  context,
                  title: isIcelandic ? "Panta Mat" : "Order Food",
                  // UPDATED SUBTITLE HERE
                  subtitle: isLoading
                      ? (isIcelandic ? "Sæki matseðil..." : "Fetching menu...")
                      : (isMenuReady
                            ? _getWeekRange()
                            : (isIcelandic
                                  ? "Matseðill ekki klár"
                                  : "Menu not ready")),
                  icon: Icons.restaurant_menu_rounded,
                  color: isMenuReady ? Colors.orange : Colors.grey.shade400,
                  onTap: isMenuReady
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DaySelectionScreen(
                                isIcelandic: isIcelandic,
                                menuNotifier: menuNotifier,
                                onRefresh: onRefresh,
                              ),
                            ),
                          );
                        }
                      : () {},
                ),
                const SizedBox(height: 24),
                _buildBigButton(
                  context,
                  title: isIcelandic ? "Mínar Pantanir" : "My Orders",
                  subtitle: isIcelandic
                      ? "Saga og yfirlit"
                      : "History & Overview",
                  icon: Icons.history_rounded,
                  color: Colors.blueGrey.shade700,
                  onTap: () {
                    // Future History Screen
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBigButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
