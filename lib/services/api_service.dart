import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/meal.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String _url =
      'https://script.google.com/macros/s/AKfycbx7qzp03MJsYfl995qcV-W3sq4yrHpcXQxT_4Wdno1DA4-X3InVF1fq-aTxtEgl6GmD/exec';

  // 1. Fetch Menu
  static Future<List<Meal>> fetchMenu() async {
    try {
      final response = await http.get(Uri.parse('$_url?action=getMenu'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Meal.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Submit Order
  static Future<bool> submitOrder({
    required String mealName,
    required String manualName,
    required String mealDate,
    required String mealDay,
    required String description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final response = await http.post(
        Uri.parse(_url),
        body: {
          'action': 'submitOrder', // Must match the Script
          'email': user?.email ?? '', // Key name must match Script data.email
          'name': manualName,
          'mealName': mealName,
          'mealDate': mealDate,
          'mealDay': mealDay,
          'description': description,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> cancelOrder({required String mealDate}) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final response = await http.post(
        Uri.parse(_url),
        body: {
          "action": "cancelOrder",
          "userEmail": user?.email ?? "",
          "mealDate": mealDate,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Fetch Ordered Dates (Normalized)
  static Future<List<String>> fetchOrderedDates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_url?action=getUserOrders&email=${user!.email}'),
      );
      if (response.statusCode == 200) {
        List<dynamic> orders = json.decode(response.body);
        return orders.map((order) {
          String rawDate = order['mealDate'].toString();
          // Get the meal name from the sheet (Column F in your script)
          String mealName = order['mealName'] ?? "Unknown";

          String formattedDate = rawDate;
          if (rawDate.contains('T')) {
            try {
              formattedDate = DateFormat(
                'dd.MM.yyyy',
              ).format(DateTime.parse(rawDate));
            } catch (_) {}
          } else {
            formattedDate = rawDate.replaceAll('/', '.');
          }
          // IMPORTANT: Return format "Date|Name"
          return "$formattedDate|$mealName";
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // New method to fetch full order history details for MyOrdersScreen
  static Future<List<dynamic>> fetchOrderHistoryDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_url?action=getUserOrders&email=${user.email}'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
