import 'dart:math';

class InventoryPredictor {
  
  // ───────── Predict Demand ─────────
  // Mock ML model that forecasts demand for the next 24 hours
  Future<Map<String, double>> predictDemand(String vendorId) async {
    print("InventoryPredictor: Analyzing historical order data for Vendor $vendorId...");
    await Future.delayed(const Duration(seconds: 1));

    // Mock demand data: Product Name -> Predicted Quantity needed
    return {
      'Fresh Tomatoes': 12.5,
      'Full Cream Milk': 8.0,
      'White Bread': 5.2,
      'Potato Chips': 15.0,
    };
  }

  // ───────── Generate Restock Alert ─────────
  Future<List<String>> generateRestockAlerts(Map<String, int> currentStock, Map<String, double> predictedDemand) async {
    List<String> alerts = [];
    
    predictedDemand.forEach((product, demand) {
      int current = currentStock[product] ?? 0;
      if (current < demand) {
        alerts.add("Alert: '$product' is predicted to run out in the next 24 hours. Predicted: ${demand.toInt()}, Current: $current");
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
}
