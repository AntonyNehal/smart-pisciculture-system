import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_pisciculture_system/pages/WeatherDetailsPage.dart';
import 'package:smart_pisciculture_system/pages/signin_page.dart';
import 'package:smart_pisciculture_system/services/auth_services.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String currentDate = DateFormat('EEE, MMM d').format(DateTime.now());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userName;
  // Sensor data (dummy for now)
  double temperatureSensor = 27.5;
  double pH = 7.2;
  double dissolvedOxygen = 5.8;
  double ammonia = 0.03;
  double waterLevel = 85; // percentage

  // Weather data
  String weatherTemp = "";
  String weatherDesc = "";
  String weatherIconCode = "";
  String city = "kochi";
  String apiKey = "1bc629f9d792f376b5c854b24e1b0b7b";

  IconData getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny;
      case '01n':
        return Icons.nights_stay;
      case '02d':
      case '02n':
        return Icons.cloud;
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return Icons.cloud_queue;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icons.grain;
      case '11d':
      case '11n':
        return Icons.flash_on;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }

  Color getWeatherColor(String iconCode) {
    if (iconCode.contains('n')) return Colors.blueGrey;
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) {
      return Colors.blue;
    }
    if (iconCode.startsWith('11')) return Colors.deepPurple;
    if (iconCode.startsWith('13')) return Colors.lightBlueAccent;
    return Colors.orange;
  }

  @override
  void initState() {
    super.initState();
    fetchWeather();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore.collection("users").doc(uid).get();
        if (doc.exists) {
          setState(() {
            userName = doc["name"];
          });
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  Future<void> fetchWeather() async {
    String url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          weatherTemp = "${data['main']['temp']}°C";
          weatherDesc = data['weather'][0]['description'];
          weatherIconCode = data['weather'][0]['icon']; // set icon here
        });
      } else {
        print("Weather API error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text("Mee Mee"),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthServices().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
                (route) => false, // removes all previous routes
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting with user name
            Text(
              userName != null ? "Hello, $userName 👋" : "Hello 👋",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              currentDate,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Weather card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WeatherDetailsPage(city: city), // Pass city name
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(248, 168, 230, 224),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      getWeatherIcon(weatherIconCode),
                      size: 40,
                      color: getWeatherColor(weatherIconCode),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weather in $city",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          weatherTemp.isNotEmpty
                              ? "$weatherTemp • $weatherDesc"
                              : "Loading...",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sensor readings
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                buildSensorCard(
                  Icons.thermostat,
                  "Temperature",
                  "$temperatureSensor°C",
                  Colors.red,
                ),
                buildSensorCard(Icons.water, "pH Level", "$pH", Colors.green),
                buildSensorCard(
                  Icons.bubble_chart,
                  "DO",
                  "$dissolvedOxygen mg/L",
                  Colors.blue,
                ),
                buildSensorCard(
                  Icons.science,
                  "Ammonia",
                  "$ammonia ppm",
                  Colors.purple,
                ),
                buildSensorCard(
                  Icons.waves,
                  "Water Level",
                  "$waterLevel%",
                  Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSensorCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
