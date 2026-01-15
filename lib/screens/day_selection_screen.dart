import 'package:flutter/material.dart';
import 'meal_detail_screen.dart';
import '../models/meal.dart';

class DaySelectionScreen extends StatefulWidget {
  final bool isIcelandic;
  final ValueNotifier<List<Meal>> menuNotifier;
  final ValueNotifier<List<String>> orderedDatesNotifier;
  final Future<void> Function() onRefresh;
  final String closingTime;

  const DaySelectionScreen({
    super.key,
    required this.isIcelandic,
    required this.menuNotifier,
    required this.orderedDatesNotifier,
    required this.onRefresh,
    required this.closingTime,
  });

  @override
  State<DaySelectionScreen> createState() => _DaySelectionScreenState();
}

class _DaySelectionScreenState extends State<DaySelectionScreen> {
  String _translateDay(String day) {
    if (!widget.isIcelandic) return day;
    final dayMap = {
      'Monday': 'Mánudagur',
      'Tuesday': 'Þriðjudagur',
      'Wednesday': 'Miðvikudagur',
      'Thursday': 'Fimmtudagur',
      'Friday': 'Föstudagur',
      'Saturday': 'Laugardagur',
      'Sunday': 'Sunnudagur',
    };
    return dayMap[day] ?? day;
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
    
    // Dynamic Closing Time Logic
    if (mealMidnight.isAtSameMomentAs(todayMidnight)) {
      try {
        List<String> parts = widget.closingTime.split(':');
        int closeHour = int.parse(parts[0]);
        int closeMinute = int.parse(parts[1]);
        
        DateTime closing = DateTime(now.year, now.month, now.day, closeHour, closeMinute);
        if (now.isAfter(closing)) return false;
      } catch (e) {
        // Fallback to 09:30 if parsing fails
        if (now.hour > 9 || (now.hour == 9 && now.minute >= 30)) return false;
      }
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
          widget.isIcelandic ? "Velja dag" : "Pick the day",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: widget.orderedDatesNotifier,
        builder: (context, orderedDates, child) {
          return ValueListenableBuilder<List<Meal>>(
            valueListenable: widget.menuNotifier,
            builder: (context, currentMeals, child) {
              if (currentMeals.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }
              return _buildDayList(context, currentMeals, orderedDates);
            },
          );
        },
      ),
    );
  }

  Widget _buildDayList(
    BuildContext context,
    List<Meal> mealsForList,
    List<String> orderedDates,
  ) {
    final seenDates = <String>{};
    final uniqueDays = mealsForList
        .where((meal) => seenDates.add(meal.fullDate))
        .toList();

    return ListView.builder(
      key: ValueKey(mealsForList.hashCode ^ orderedDates.hashCode),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: uniqueDays.length,
      itemBuilder: (context, index) {
        final meal = uniqueDays[index];
        bool available = _isDayAvailable(meal.fullDate);
        String formattedMealDate = meal.date.replaceAll('/', '.');

        // UPDATED LOGIC: Check if any order string STARTS with this date
        bool alreadyOrdered = orderedDates.any(
          (o) => o.startsWith(formattedMealDate),
        );

        return Card(
          elevation: (available && !alreadyOrdered) ? 2 : 0,
          color: !available
              ? Colors.grey.shade50
              : (alreadyOrdered ? Colors.green.shade50 : Colors.white),
          margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: !available
                  ? Colors.transparent
                  : (alreadyOrdered
                        ? Colors.green.shade200
                        : Colors.blueGrey.shade100),
            ),
          ),
          child: ListTile(
            leading: Icon(
              !available
                  ? Icons.lock_outline_rounded
                  : (alreadyOrdered
                        ? Icons.check_circle_rounded
                        : Icons.calendar_today_rounded),
              color: !available
                  ? Colors.blueGrey.shade200
                  : (alreadyOrdered ? Colors.green : Colors.orange),
            ),
            title: Row(
              children: [
                SizedBox(
                  width: 115,
                  child: Text(
                    _translateDay(meal.day),
                    style: TextStyle(
                      color: !available
                          ? Colors.grey
                          : Colors.blueGrey.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (alreadyOrdered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: !available ? Colors.grey.shade400 : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.isIcelandic ? "PANTAÐ" : "ORDERED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(formattedMealDate),
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
                        orderedDatesNotifier: widget.orderedDatesNotifier,
                        closingTime: widget.closingTime,
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
          widget.isIcelandic ? "Lokað" : "Closed",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          "Kl. ${widget.closingTime}",
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
