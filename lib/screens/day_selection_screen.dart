import 'package:flutter/material.dart';
import 'meal_detail_screen.dart';
import '../models/meal.dart';

class DaySelectionScreen extends StatefulWidget {
  final bool isIcelandic;
  // CHANGE 1: Accept the Notifier
  final ValueNotifier<List<Meal>> menuNotifier;
  final Future<void> Function() onRefresh;

  const DaySelectionScreen({
    super.key,
    required this.isIcelandic,
    required this.menuNotifier,
    required this.onRefresh,
  });

  @override
  State<DaySelectionScreen> createState() => _DaySelectionScreenState();
}

class _DaySelectionScreenState extends State<DaySelectionScreen> {
  bool _localLoading = false;

  Future<void> _handleRefresh() async {
    setState(() => _localLoading = true);
    try {
      // Calling this updates the notifier in main.dart
      // Because we are listening to that notifier below, the UI updates automatically
      await widget.onRefresh();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _localLoading = false);
    }
  }

  bool _isDayAvailable(String fullDateStr) {
    DateTime now = DateTime.now();
    DateTime? mealDate = DateTime.tryParse(fullDateStr);
    if (mealDate == null) return false;
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    DateTime mealMidnight = DateTime(
      mealDate.year,
      mealDate.month,
      mealDate.day,
    );
    if (mealMidnight.isBefore(todayMidnight)) return false;
    if (mealMidnight.isAtSameMomentAs(todayMidnight) && now.hour >= 10) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isIcelandic ? "Velja Dag" : "Pick the day",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Row(
            children: [
              Text(
                widget.isIcelandic ? "Endursækja " : "Refresh ",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              if (_localLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: _handleRefresh,
                ),
            ],
          ),
        ],
      ),
      // CHANGE 2: ValueListenableBuilder listens to the notifier
      body: ValueListenableBuilder<List<Meal>>(
        valueListenable: widget.menuNotifier,
        builder: (context, currentMeals, child) {
          return Stack(
            children: [
              currentMeals.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : _buildDayList(context, currentMeals),
              if (_localLoading) _buildLoadingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayList(BuildContext context, List<Meal> mealsForList) {
    final seenDates = <String>{};
    final uniqueDays = mealsForList
        .where((meal) => seenDates.add(meal.fullDate))
        .toList();

    return ListView.builder(
      // We still use a key, but now the ValueListenableBuilder handles the rebuild trigger
      key: ValueKey(mealsForList.hashCode),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: uniqueDays.length,
      itemBuilder: (context, index) {
        final meal = uniqueDays[index];
        bool available = _isDayAvailable(meal.fullDate);
        return Card(
          elevation: 2,
          shadowColor: Colors.blueGrey.withValues(alpha: 0.1),
          color: available ? Colors.white : Colors.grey.shade50,
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: available ? Colors.blueGrey.shade100 : Colors.transparent,
            ),
          ),
          child: ListTile(
            leading: Icon(
              available
                  ? Icons.calendar_today_rounded
                  : Icons.lock_outline_rounded,
              color: available ? Colors.orange : Colors.blueGrey.shade300,
            ),
            title: Text(
              meal.day,
              style: TextStyle(
                color: available ? Colors.blueGrey.shade900 : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              meal.date,
              style: TextStyle(color: Colors.blueGrey.shade400),
            ),
            trailing: available
                ? const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.orange,
                    size: 16,
                  )
                : _buildLockWidget(),
            onTap: available
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => MealDetailScreen(
                        date: meal.fullDate,
                        allMeals: mealsForList,
                        isIcelandic: widget.isIcelandic,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildLockWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          widget.isIcelandic ? "Lokað" : "Locked",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          widget.isIcelandic ? "Eftir kl. 10:00" : "Past 10:00 AM",
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              widget.isIcelandic ? "Uppfæri matseðil..." : "Updating menu...",
              style: TextStyle(
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
