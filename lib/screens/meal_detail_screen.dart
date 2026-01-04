import 'package:flutter/material.dart';
import '../models/meal.dart';

class MealDetailScreen extends StatelessWidget {
  final String date;
  final List<Meal> allMeals;
  final bool isIcelandic;

  const MealDetailScreen({
    super.key,
    required this.date,
    required this.allMeals,
    required this.isIcelandic,
  });

  @override
  Widget build(BuildContext context) {
    // Filter meals for the selected date
    final dailyMeals = allMeals.where((m) => m.fullDate == date).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isIcelandic ? "Matseðill" : "Menu",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dailyMeals.length,
        itemBuilder: (context, index) {
          final meal = dailyMeals[index];
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueGrey.shade50),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withAlpha(13),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isIcelandic ? meal.mealNameIs : meal.mealName,
                        style: TextStyle(
                          color: Colors.blueGrey.shade900,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 30, color: Colors.blueGrey.shade50),
                Text(
                  isIcelandic ? meal.descriptionIs : meal.descriptionEn,
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // ACTION COLOR
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _showOrderConfirmation(context, meal),
                    child: Text(
                      isIcelandic ? "PANTA NÚNA" : "ORDER NOW",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context, Meal meal) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isIcelandic ? "Staðfesta pöntun" : "Confirm Order",
          style: TextStyle(
            color: Colors.blueGrey.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: isIcelandic ? "Nafn pöntunara" : "Your Name",
            labelStyle: TextStyle(color: Colors.blueGrey.shade400),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isIcelandic ? "Hætta við" : "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.blueGrey.shade900, // THE "SECURE" SUBMIT COLOR
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                // 1. Hide the dialog
                Navigator.pop(context);

                // 2. TRIGGER THE SNACKBAR HERE
                _showSuccessSnackBar(context);

                // 3. For now, we won't do anything else,
                // but we'll add an API call here in the future
              } else {
                // Optional: Show a message if name is empty
              }
            },
            child: Text(isIcelandic ? "Senda" : "Submit"),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isIcelandic ? "Pöntun móttekin!" : "Order received!"),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
