import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MyOrdersScreen extends StatefulWidget {
  final bool isIcelandic;
  final ValueNotifier<List<String>> orderedDatesNotifier;

  const MyOrdersScreen({
    super.key,
    required this.isIcelandic,
    required this.orderedDatesNotifier,
  });

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // 1. HELPER: Translate days to Icelandic
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

  // 2. HELPER: Format date to 09.01.2026
  String _formatMealDate(dynamic rawDate) {
    if (rawDate == null) return "";
    String dateStr = rawDate.toString();
    try {
      DateTime dt = dateStr.contains('T')
          ? DateTime.parse(dateStr)
          : DateFormat("dd/MM/yyyy").parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (e) {
      return dateStr.replaceAll('/', '.');
    }
  }

  // 3. HELPER: Sort Oldest First (Ascending)
  List<dynamic> _sortOrders(List<dynamic> orders) {
    orders.sort((a, b) {
      try {
        DateTime dateA = a['mealDate'].toString().contains('T')
            ? DateTime.parse(a['mealDate'])
            : DateFormat("dd/MM/yyyy").parse(a['mealDate']);
        DateTime dateB = b['mealDate'].toString().contains('T')
            ? DateTime.parse(b['mealDate'])
            : DateFormat("dd/MM/yyyy").parse(b['mealDate']);
        return dateA.compareTo(dateB); // Oldest First
      } catch (e) {
        return 0;
      }
    });
    return orders;
  }

  bool _isFinished(dynamic rawDate) {
    if (rawDate == null) return false;
    try {
      DateTime mealDate = rawDate.toString().contains('T')
          ? DateTime.parse(rawDate.toString())
          : DateFormat("dd/MM/yyyy").parse(rawDate.toString());
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final mealMidnight = DateTime(
        mealDate.year,
        mealDate.month,
        mealDate.day,
      );

      if (mealMidnight.isBefore(todayMidnight)) return true;
      if (mealMidnight.isAtSameMomentAs(todayMidnight) && now.hour >= 10) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleDeleteOrder(dynamic order) async {
    // 1. Show Confirmation Dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(widget.isIcelandic ? "Eyða pöntun?" : "Delete Order?"),
        content: Text(
          widget.isIcelandic
              ? "Ertu viss um að þú viljir eyða þessari pöntun?"
              : "Are you sure you want to delete this order?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              widget.isIcelandic ? "Hætta við" : "Cancel",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              widget.isIcelandic ? "Eyða" : "Delete",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Perform Deletion
    String rawDate = order['mealDate'].toString();
    String apiDate = _formatMealDate(rawDate);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    bool success = await ApiService.cancelOrder(mealDate: apiDate);

    if (!mounted) return;
    Navigator.pop(context); // Remove loading indicator

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isIcelandic ? "Pöntun eytt" : "Order deleted"),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {}); // Refresh the FutureBuilder

      // Sync with global notifier so DaySelectionScreen updates immediately
      ApiService.fetchOrderedDates().then((updatedList) {
        widget.orderedDatesNotifier.value = updatedList;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isIcelandic
                ? "Ekki tókst að eyða pöntun"
                : "Failed to delete order",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: Text(
          widget.isIcelandic ? "Mínar pantanir" : "My Orders",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.fetchOrderHistoryDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                widget.isIcelandic
                    ? "Engar pantanir fundust"
                    : "No orders found",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            );
          }

          final orders = _sortOrders(List.from(snapshot.data!));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final dayTranslated = _translateDay(order['mealDay'] ?? "");
              final dateFormatted = _formatMealDate(order['mealDate']);
              final description = order['description']?.toString() ?? "";
              final finished = _isFinished(order['mealDate']);

              return Opacity(
                opacity: finished ? 0.6 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Day & Date Header (Now more prominent)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: finished
                                  ? Colors.grey.shade400
                                  : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${dayTranslated.toUpperCase()}  •  $dateFormatted",
                              style: TextStyle(
                                color: finished
                                    ? Colors.grey.shade400
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            if (finished)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.grey,
                                size: 24,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // 2. Meal Name with Icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.restaurant_menu_rounded,
                              size: 24,
                              color: finished
                                  ? Colors.grey.shade400
                                  : Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                order['mealName'] ?? "",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  color: finished
                                      ? Colors.blueGrey.shade300
                                      : Colors.blueGrey.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(height: 32),
                        
                        // 3. Description
                        if (description.trim().isNotEmpty) ...[
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 15,
                              color: finished
                                  ? Colors.grey.shade400
                                  : Colors.blueGrey.shade600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // 4. Action / Status & Timestamp Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Timestamp (Bottom Left)
                            Expanded(
                              child: Text(
                                widget.isIcelandic
                                    ? "Pantað: ${order['orderedAt'] ?? ""}"
                                    : "Ordered: ${order['orderedAt'] ?? ""}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            
                            // Status or Cancel Button
                            if (finished)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  widget.isIcelandic ? "LOKIÐ" : "FINISHED",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => _handleDeleteOrder(order),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  backgroundColor: Colors.redAccent.withValues(
                                    alpha: 0.05,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  widget.isIcelandic ? "Hætta við" : "Cancel",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
