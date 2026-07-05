import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryPredictor {
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────── Predict Local Demand ─────────
  Future<Map<String, double>> predictDemand(String vendorId) async {
    print("InventoryPredictor: Calculating local demand for vendor...");
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      
      final querySnapshot = await _db.collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      Map<String, int> productSales = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['created_at'] != null) {
          final Timestamp ts = data['created_at'];
          final DateTime createdAt = ts.toDate();
          if (createdAt.isAfter(yesterday)) {
            final items = data['items'] as List<dynamic>? ?? [];
            for (var item in items) {
              final productName = item['name'] as String?;
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              if (productName != null) {
                productSales[productName] = (productSales[productName] ?? 0) + quantity;
              }
            }
          }
        }
      }

      Map<String, double> topProducts = {};
      productSales.forEach((key, value) {
        topProducts[key] = value.toDouble();
      });

      return topProducts;
    } catch (e) {
      print("InventoryPredictor: Error fetching local demand ($e).");
      return {};
    }
  }

  // ───────── Predict Global Demand ─────────
  Future<Map<String, double>> getGlobalDemand() async {
    print("InventoryPredictor: Calculating High Demand Products globally from last 24 hours...");
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      
      // Query all orders globally across the app
      final querySnapshot = await _db.collection('orders').get();

      Map<String, int> productSales = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        if (data['created_at'] != null) {
          final Timestamp ts = data['created_at'];
          final DateTime createdAt = ts.toDate();
          if (createdAt.isAfter(yesterday)) {
            final items = data['items'] as List<dynamic>? ?? [];
            for (var item in items) {
              final productName = item['name'] as String?;
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              if (productName != null) {
                productSales[productName] = (productSales[productName] ?? 0) + quantity;
              }
            }
          }
        }
      }

      var sortedSales = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
        
      // Take only the top 5 (if there are fewer than 5, it naturally takes what's available)
      var top5 = sortedSales.take(5).toList();
      
      Map<String, double> topProducts = {};
      for (var entry in top5) {
        topProducts[entry.key] = entry.value.toDouble();
      }

      return topProducts;
    } catch (e) {
      print("InventoryPredictor: Error fetching global demand ($e).");
      return {};
    }
  }

  // ───────── Generate Restock Alert ─────────
  Future<List<String>> generateRestockAlerts(Map<String, int> currentStock, Map<String, double> predictedDemand) async {
    List<String> alerts = [];
    
    predictedDemand.forEach((product, demand) {
      if (currentStock.containsKey(product)) {
        int current = currentStock[product]!;
        if (current < demand) {
          alerts.add("Alert: '$product' is in high demand and running low. Ordered: ${demand.toInt()}, Current: $current");
        }
      }
    });

    return alerts;
  }

  // ───────── Mock Linear Regression Data ─────────
  List<Map<String, dynamic>> getDemandTrendData() {
    return [
      {'day': 'Mon', 'demand': 40},
      {'day': 'Tue', 'demand': 35},
      {'day': 'Wed', 'demand': 55},
      {'day': 'Thu', 'demand': 45},
      {'day': 'Fri', 'demand': 80},
      {'day': 'Sat', 'demand': 95},
      {'day': 'Sun', 'demand': 70},
    ];
  }

  // ───────── AI Forecast (Real Scikit-Learn Model on Render) ─────────
  // Standalone, on-demand only — never called automatically on screen load,
  // so a sleeping/slow Render free-tier instance never blocks the main dashboard.
  Future<Map<String, dynamic>> getAIForecast(List<String> products) async {
    const String mlApiUrl = 'https://speedygrocer-ml.onrender.com/predict';

    try {
      final response = await http.post(
        Uri.parse(mlApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'products': products}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'predictions': Map<String, dynamic>.from(data['predictedDemand'] ?? {}),
        };
      }
      return {'success': false, 'error': 'Server returned ${response.statusCode}'};
    } on TimeoutException {
      return {'success': false, 'error': 'timeout'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
