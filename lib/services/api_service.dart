import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.5:5000";

  static Future<int> predictFish(
      String species, int age, int feed) async {

    final response = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "species": species,
        "age_days": age,
        "feed_per_day": feed
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["harvest_days"];
    } else {
      throw Exception("Prediction failed");
    }
  }
}