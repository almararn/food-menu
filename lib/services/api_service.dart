import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

class ApiService {
  // Add 'static' here so you can call it without creating an instance
  static Future<List<Meal>> fetchMenu() async {
    const url =
        'https://script.google.com/macros/s/AKfycbxbdSWRScm6bVB4kl0ofoo_NFJDnwmZktXCBhJoaMAY_1Oi1GyS8lMjsYT9NJP8CRSP/exec';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Meal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load menu');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
