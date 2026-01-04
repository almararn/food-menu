class Meal {
  final String day;
  final String date; // The "29/12/2025" from the sheet
  final String fullDate; // The "2025-12-29" we created for logic
  final String itemId;
  final String mealName;
  final String mealNameIs;
  final String descriptionIs;
  final String descriptionEn;

  Meal({
    required this.day,
    required this.date,
    required this.fullDate,
    required this.itemId,
    required this.mealName,
    required this.mealNameIs,
    required this.descriptionIs,
    required this.descriptionEn,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      day: json['day'] ?? '',
      date: json['date'] ?? '',
      fullDate: json['full_date'] ?? '', // This matches the key in doGet
      itemId: json['item_id'] ?? '',
      mealName: json['meal_name'] ?? '',
      mealNameIs: json['meal_name_is'] ?? '',
      descriptionIs: json['description_is'] ?? '',
      descriptionEn: json['description_en'] ?? '',
    );
  }
}
