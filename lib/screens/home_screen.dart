import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'day_selection_screen.dart';
import 'my_orders_screen.dart';
import '../models/meal.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  final bool isIcelandic;
  final VoidCallback onToggleLanguage;
  final ValueNotifier<List<Meal>> menuNotifier;
  final ValueNotifier<List<String>> orderedDatesNotifier;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final String closingTime;

  const HomeScreen({
    super.key,
    required this.isIcelandic,
    required this.onToggleLanguage,
    required this.menuNotifier,
    required this.orderedDatesNotifier,
    required this.isLoading,
    required this.onRefresh,
    required this.closingTime,
  });

  String _getWeekRange() {
    final meals = menuNotifier.value;
    if (meals.isEmpty) return "";

    List<DateTime> dates = meals
        .map((m) => DateTime.tryParse(m.fullDate))
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return "";

    dates.sort();
    DateTime first = dates.first;
    DateTime last = dates.last;

    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    return isIcelandic
        ? "Matseðill vikunnar\n${formatter.format(first)} - ${formatter.format(last)}"
        : "Weekly Menu\n${formatter.format(first)} - ${formatter.format(last)}";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Meal>>(
      valueListenable: menuNotifier,
      builder: (context, meals, child) {
        bool isMenuReady = !isLoading && meals.isNotEmpty;
        final user = FirebaseAuth.instance.currentUser;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leadingWidth: 140, // Increased width to fit icon + text
            leading: TextButton.icon(
              onPressed: onToggleLanguage,
              icon: const Icon(
                Icons.language_rounded,
                size: 18,
                color: Colors.blueAccent,
              ),
              label: Text(
                isIcelandic ? "ENGLISH" : "ÍSLENSKA",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user?.displayName ?? user?.email?.split('@')[0] ?? "",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async => await AuthService().signOut(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isIcelandic ? "Útskrá" : "Logout",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.logout_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // FloatingActionButton Removed as requested
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: onRefresh,
                color: Colors.orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon or Logo
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 80,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "TDK Food Portal",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 56), // Space instead of the removed text
                          _buildBigButton(
                            context,
                            title: isIcelandic ? "Panta Mat" : "Order Food",
                            subtitle: isMenuReady
                                ? _getWeekRange()
                                : (isIcelandic
                                      ? "Matseðill ekki klár"
                                      : "Menu not ready"),
                            icon: Icons.fastfood,
                            color: isMenuReady
                                ? Colors.orange
                                : Colors.grey.shade400,
                            onTap: isMenuReady
                                ? () => _goToOrder(context)
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyOrdersScreen(
                                    isIcelandic: isIcelandic,
                                    orderedDatesNotifier: orderedDatesNotifier,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 60),

                          // REFRESH HINT & TIMESTAMP
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.keyboard_double_arrow_down_rounded,
                                    size: 16,
                                    color: Colors.grey.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isIcelandic
                                        ? "Draga niður til að uppfæra matseðil"
                                        : "Pull down to refresh menu",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isIcelandic
                                    ? "Síðast uppfært: ${DateFormat('HH:mm').format(DateTime.now())}"
                                    : "Last updated: ${DateFormat('HH:mm').format(DateTime.now())}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isIcelandic
                                  ? "Sæki matseðil..."
                                  : "Refreshing menu...",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _goToOrder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaySelectionScreen(
          isIcelandic: isIcelandic,
          menuNotifier: menuNotifier,
          orderedDatesNotifier: orderedDatesNotifier,
          onRefresh: onRefresh,
          closingTime: closingTime,
        ),
      ),
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
