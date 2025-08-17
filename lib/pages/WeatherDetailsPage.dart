import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class WeatherDetailsPage extends StatefulWidget {
  final String city;
  const WeatherDetailsPage({super.key, required this.city});

  @override
  State<WeatherDetailsPage> createState() => _WeatherDetailsPageState();
}

class _WeatherDetailsPageState extends State<WeatherDetailsPage> {
  Map<String, dynamic>? currentWeather;
  List<dynamic> forecast = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    const apiKey = "1bc629f9d792f376b5c854b24e1b0b7b";
    final currentUrl =
        "https://api.openweathermap.org/data/2.5/weather?q=${widget.city}&appid=$apiKey&units=metric";
    final forecastUrl =
        "https://api.openweathermap.org/data/2.5/forecast?q=${widget.city}&appid=$apiKey&units=metric";

    try {
      final currentRes = await http.get(Uri.parse(currentUrl));
      final forecastRes = await http.get(Uri.parse(forecastUrl));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(currentRes.body);
          final forecastData = json.decode(forecastRes.body);
          forecast = forecastData['list']
              .where((item) {
                final date = DateTime.parse(item['dt_txt']);
                return date.isAfter(DateTime.now()) && date.hour == 12;
              })
              .take(3)
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load weather data");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text("${widget.city} Weather"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Weather Card
                  Card(
                    color: Colors.teal.shade100,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            currentWeather!['weather'][0]['description']
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Temperature: ${currentWeather!['main']['temp']}°C",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Feels Like: ${currentWeather!['main']['feels_like']}°C",
                          ),
                          Text(
                            "Humidity: ${currentWeather!['main']['humidity']}%",
                          ),
                          Text(
                            "Pressure: ${currentWeather!['main']['pressure']} hPa",
                          ),
                          Text(
                            "Sea Level: ${currentWeather!['main']['sea_level'] ?? 'N/A'}",
                          ),
                          Text("Wind: ${currentWeather!['wind']['speed']} m/s"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Forecast Section
                  const Text(
                    "Next 3 Days Forecast",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...forecast.map((item) {
                    final date = DateTime.parse(item['dt_txt']);
                    final formattedDate = DateFormat('EEE, MMM d').format(date);
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: Colors.teal),
                        title: Text(
                          "${item['main']['temp']}°C - ${item['weather'][0]['description']}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        trailing: Text(
                          "Humidity: ${item['main']['humidity']}%",
                          style: const TextStyle(color: Colors.teal),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
