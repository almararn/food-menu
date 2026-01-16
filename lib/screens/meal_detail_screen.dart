import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import '../services/api_service.dart';

class MealDetailScreen extends StatefulWidget {
  final String date;
  final List<Meal> allMeals;
  final bool isIcelandic;
  final ValueNotifier<List<String>> orderedDatesNotifier;
  final String closingTime;

  const MealDetailScreen({
    super.key,
    required this.date,
    required this.allMeals,
    required this.isIcelandic,
    required this.orderedDatesNotifier,
    required this.closingTime,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isPastDeadline = false;
  bool _isToday = false;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _calculateTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTime() {
    final now = DateTime.now();
    try {
      DateTime mealDate;
      // Handle ISO 8601 format (yyyy-MM-dd) which is expected in widget.date
      if (widget.date.contains('-')) {
        mealDate = DateTime.parse(widget.date);
      } else {
        // Fallback for dd/MM/yyyy or dd.MM.yyyy
        String cleanDate = widget.date.replaceAll('/', '.');
        List<String> parts = cleanDate.split('.');
        mealDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      // Parse Dynamic Closing Time
      int closeHour = 9;
      int closeMinute = 30;
      try {
        List<String> parts = widget.closingTime.split(':');
        closeHour = int.parse(parts[0]);
        closeMinute = int.parse(parts[1]);
      } catch (_) {}

      DateTime deadline = DateTime(
        mealDate.year,
        mealDate.month,
        mealDate.day,
        closeHour,
        closeMinute,
      );

      if (mounted) {
        setState(() {
          _isToday =
              now.year == mealDate.year &&
              now.month == mealDate.month &&
              now.day == mealDate.day;
          _isPastDeadline = now.isAfter(deadline);
          _timeLeft = deadline.difference(now);
        });
      }
    } catch (_) {}
  }

  Future<void> _handleCancel() async {
    // Find the correct date format from the meals list
    final dailyMeals = widget.allMeals
        .where((m) => m.fullDate == widget.date)
        .toList();
    if (dailyMeals.isEmpty) return;
    String correctDate = dailyMeals.first.date;

    _showLoadingDialog(context);
    bool success = await ApiService.cancelOrder(mealDate: correctDate);
    if (mounted) Navigator.pop(context);

    if (success) {
      // Remove the order from the local list to update UI instantly
      List<String> current = List.from(widget.orderedDatesNotifier.value);
      String targetDate = correctDate.replaceAll('/', '.');
      current.removeWhere((o) => o.startsWith(targetDate));
      widget.orderedDatesNotifier.value = current;

      _showSnackBar(
        widget.isIcelandic ? "Pöntun eytt" : "Order Cancelled",
        Colors.orange,
      );

      // Wait 2 seconds before going back
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyMeals = widget.allMeals
        .where((m) => m.fullDate == widget.date)
        .toList();
    bool showCountdown =
        _isToday &&
        _timeLeft.inMinutes < 60 &&
        !_timeLeft.isNegative &&
        !_isPastDeadline;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isIcelandic ? "Matseðill" : "Menu",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [if (showCountdown) _buildCountdownBadge()],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: widget.orderedDatesNotifier,
        builder: (context, orderedDates, _) {
          // 1. Identify if this day has an order
          String normalizedDate = "";
          if (dailyMeals.isNotEmpty) {
            normalizedDate = dailyMeals.first.date.replaceAll('/', '.');
          } else {
            normalizedDate = widget.date.replaceAll('/', '.');
          }

          // Using .cast<String?>() ensures the compiler handles the potential null safely
          String? match = orderedDates.cast<String?>().firstWhere(
            (o) => o!.startsWith(normalizedDate),
            orElse: () => null,
          );

          bool dayAlreadyOrdered = match != null;
          String orderedMealName = "";

          // 2. Extract meal name
          // Removed the '!' from match because flow analysis knows it's non-null here
          if (dayAlreadyOrdered && match.contains('|')) {
            orderedMealName = match.split('|')[1].trim();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dailyMeals.length,
            itemBuilder: (context, index) {
              final meal = dailyMeals[index];
              final mealNameOnScreen = widget.isIcelandic
                  ? meal.mealNameIs
                  : meal.mealName;

              final description = widget.isIcelandic
                  ? meal.descriptionIs
                  : meal.descriptionEn;
              final bool isUnavailable = description.trim().isEmpty;

              // 3. Match logic: Should this specific card show the "Cancel" button?
              // FIX: Check against BOTH languages because the order might have been saved in the other language.
              bool isThisOrderedMeal =
                  (orderedMealName == meal.mealName.trim() ||
                  orderedMealName == meal.mealNameIs.trim());

              return _buildMealCard(
                meal,
                mealNameOnScreen,
                description,
                canOrder:
                    !_isPastDeadline && !dayAlreadyOrdered && !isUnavailable,
                dayAlreadyOrdered: dayAlreadyOrdered,
                showCancel: isThisOrderedMeal && !_isPastDeadline,
                isUnavailable: isUnavailable,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMealCard(
    Meal meal,
    String name,
    String desc, {
    required bool canOrder,
    required bool dayAlreadyOrdered,
    required bool showCancel,
    required bool isUnavailable,
  }) {
    return Opacity(
      opacity: isUnavailable ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            Text(
              isUnavailable
                  ? (widget.isIcelandic ? "Ekki í boði" : "Not available")
                  : desc,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: isUnavailable ? Colors.redAccent : Colors.black87,
                fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 32),
            if (showCancel)
              _buildCancelAction()
            else
              _buildOrderAction(
                meal,
                canOrder,
                dayAlreadyOrdered,
                isUnavailable,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderAction(
    Meal meal,
    bool canOrder,
    bool dayAlreadyOrdered,
    bool isUnavailable,
  ) {
    String label;
    if (isUnavailable) {
      label = widget.isIcelandic ? "EKKI Í BOÐI" : "NOT AVAILABLE";
    } else if (_isPastDeadline) {
      label = widget.isIcelandic ? "LOKAÐ" : "CLOSED";
    } else if (dayAlreadyOrdered) {
      label = widget.isIcelandic ? "PÖNTUN LOKAÐ" : "ORDER CLOSED";
    } else {
      label = widget.isIcelandic ? "PANTA NÚNA" : "ORDER NOW";
    }

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canOrder ? Colors.orange : Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: canOrder ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: canOrder ? () => _showOrderConfirmation(meal) : null,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCancelAction() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _handleCancel,
        child: Text(
          widget.isIcelandic ? "HÆTTA VIÐ PÖNTUN" : "CANCEL ORDER",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBadge() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "${_timeLeft.inMinutes.toString().padLeft(2, '0')}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _showOrderConfirmation(Meal meal) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('saved_user_name');

    final nameController = TextEditingController(
      text:
          savedName ?? (user?.displayName ?? user?.email?.split('@')[0] ?? ""),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.isIcelandic ? "Staðfesta pöntun" : "Confirm Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: widget.isIcelandic ? "Nafn" : "Name",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.isIcelandic ? "Hætta við" : "Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final mName = widget.isIcelandic
                  ? meal.mealNameIs
                  : meal.mealName;

              // Save the name for next time
              await prefs.setString('saved_user_name', nameController.text);

              Navigator.pop(ctx);
              _showLoadingDialog(context);

              bool success = await ApiService.submitOrder(
                mealName: mName,
                manualName: nameController.text,
                mealDate: meal.date,
                mealDay: meal.day,
                description: widget.isIcelandic
                    ? meal.descriptionIs
                    : meal.descriptionEn,
              );

              if (mounted) Navigator.pop(context);
              if (success && mounted) {
                // Add "Date|Name" to trigger the local UI update
                String newOrder = "${meal.date.replaceAll('/', '.')}|$mName";
                widget.orderedDatesNotifier.value = List<String>.from(
                  widget.orderedDatesNotifier.value,
                )..add(newOrder);

                _showSnackBar(
                  widget.isIcelandic ? "Pöntun staðfest" : "Order placed",
                  Colors.green,
                );

                // Wait 1 second before going back
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(
              widget.isIcelandic ? "Staðfesta" : "Confirm",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) =>
        const Center(child: CircularProgressIndicator(color: Colors.orange)),
  );

  void _showSnackBar(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
}
