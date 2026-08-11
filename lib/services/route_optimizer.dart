import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class RouteData {
  final List<Map<String, double>> polyline;
  final String durationText;
  final int durationValue;
  final String distanceText;
  final int distanceValue;

  RouteData({
    required this.polyline,
    required this.durationText,
    required this.durationValue,
    required this.distanceText,
    required this.distanceValue,
  });
}

class RouteOptimizer {
  final String _apiKey = 'AIzaSyD7akEvTjFKMcpWBGd12QGzY78IYYpXPwk';
  
  // ───────── Calculate Optimal Route ─────────
  Future<RouteData?> calculateRoute(
    Map<String, double> start, 
    Map<String, double> end
  ) async {
    if (_apiKey.isEmpty) {
      print("RouteOptimizer ERROR: Maps API key is empty! Route will fall back to straight line.");
      return null;
    }

    final baseUrl = "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${start['lat']},${start['lng']}"
        "&destination=${end['lat']},${end['lng']}"
        "&mode=driving"
        "&key=$_apiKey";

    // On web, we need a CORS proxy. Try multiple in case one is down.
    final List<String> urlsToTry = kIsWeb
        ? [
            "https://api.allorigins.win/raw?url=${Uri.encodeComponent(baseUrl)}",
            "https://corsproxy.io/?url=${Uri.encodeComponent(baseUrl)}",
            "https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(baseUrl)}",
            "https://thingproxy.freeboard.io/fetch/$baseUrl",
          ]
        : [baseUrl];

    for (final url in urlsToTry) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final route = data['routes'][0];
            final leg = route['legs'][0];
            final String points = route['overview_polyline']['points'];
            print("RouteOptimizer: Got route — ${leg['duration']['text']}, ${leg['distance']['text']}");
            return RouteData(
              polyline: _decodePolyline(points),
              durationText: leg['duration']['text'],
              durationValue: leg['duration']['value'],
              distanceText: leg['distance']['text'],
              distanceValue: leg['distance']['value'],
            );
          } else {
            print("RouteOptimizer Directions API Error: ${data['status']} — ${data['error_message'] ?? ''}");
            break;
          }
        } else {
          print("RouteOptimizer HTTP Error via $url: ${response.statusCode}");
        }
      } catch (e) {
        print("RouteOptimizer Exception via $url: $e");
      }
    }

    return _fetchOsrmRoute(start, end);
  }

  Future<RouteData?> _fetchOsrmRoute(
    Map<String, double> start,
    Map<String, double> end,
  ) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${start['lng']},${start['lat']};'
        '${end['lng']},${end['lat']}'
        '?overview=full&geometries=polyline';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data['code'] != 'Ok' || (data['routes'] as List?)?.isEmpty != false) {
        return null;
      }

      final route = data['routes'][0];
      final String points = route['geometry'];
      final double durationSeconds = (route['duration'] as num).toDouble();
      final double distanceMeters = (route['distance'] as num).toDouble();

      return RouteData(
        polyline: _decodePolyline(points),
        durationText: _formatDuration(durationSeconds.round()),
        durationValue: durationSeconds.round(),
        distanceText: _formatDistance(distanceMeters.round()),
        distanceValue: distanceMeters.round(),
      );
    } catch (e) {
      print('RouteOptimizer OSRM fallback failed: $e');
      return null;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0 ? '$hours hr' : '$hours hr $remainingMinutes min';
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  // ───────── Decode Google Maps Polyline ─────────
  List<Map<String, double>> _decodePolyline(String poly) {
    var list = poly.codeUnits;
    var lList = <Map<String, double>>[];
    int index = 0;
    int len = poly.length;
    int c = 0;
    int lat = 0;
    int lng = 0;
    
    while (index < len) {
      int shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << shift;
        shift += 5;
        index++;
      } while (c >= 32);
      lat += ((result & 1) == 1 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << shift;
        shift += 5;
        index++;
      } while (c >= 32);
      lng += ((result & 1) == 1 ? ~(result >> 1) : (result >> 1));

      lList.add({
        'lat': lat / 100000.0,
        'lng': lng / 100000.0,
      });
    }

    return lList;
  }
}

