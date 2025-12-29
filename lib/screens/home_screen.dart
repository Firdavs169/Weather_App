import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _weatherService = WeatherService();

  Weather? _weather;
  String? _error;
  bool _isLoading = false;
  
  // NEW: History list
  List<String> _searchHistory = [];

  void _getWeather() async {
    if (_controller.text.isEmpty) {
      setState(() => _error = 'Please enter a city name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _weather = null;
    });

    try {
      final weather = await _weatherService.fetchWeather(_controller.text);
      setState(() {
        _weather = weather;
        // NEW: Add to history (avoid duplicates)
        if (!_searchHistory.contains(weather.city)) {
          _searchHistory.insert(0, weather.city);
          if (_searchHistory.length > 10) {
            _searchHistory.removeLast();
          }
        }
      });
    } catch (e) {
      setState(() => _error = 'City not found');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position?> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _error = 'Location services disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _getWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _weather = null;
    });

    try {
      final position = await _determinePosition();
      if (position == null) return;

      final weather = await _weatherService.fetchWeatherByCoords(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _weather = weather;
        // NEW: Add to history
        if (!_searchHistory.contains(weather.city)) {
          _searchHistory.insert(0, weather.city);
          if (_searchHistory.length > 10) {
            _searchHistory.removeLast();
          }
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // NEW: Search from history
  void _searchFromHistory(String city) {
    _controller.text = city;
    _getWeather();
  }

  // NEW: Clear history
  void _clearHistory() {
    setState(() => _searchHistory.clear());
  }

  List<Color> _getBackgroundColors() {
    if (_weather == null) {
      return [Colors.lightBlue, Colors.lightBlueAccent];
    }

    final desc = _weather!.description.toLowerCase();

    if (desc.contains('clear')) return [Colors.orange, Colors.yellow];
    if (desc.contains('rain')) return [Colors.blueGrey, Colors.blue];
    if (desc.contains('cloud')) return [Colors.grey, Colors.blueGrey];
    if (desc.contains('snow')) return [Colors.white, Colors.lightBlue];
    if (desc.contains('storm')) return [Colors.deepPurple, Colors.black];

    return [Colors.lightBlue, Colors.lightBlueAccent];
  }

  String weatherAnimationUrl() {
    if (_weather == null) {
      return 'https://assets10.lottiefiles.com/packages/lf20_jcikwtux.json';
    }

    final desc = _weather!.description.toLowerCase();

    if (desc.contains('clear')) {
      return 'https://lottie.host/548525b9-4909-4529-bcd7-ca39989cc049/tU9HiLwyWU.json';
    }
    if (desc.contains('rain')) {
      return 'https://lottie.host/1f668d27-8cb3-4434-84d7-505c8ca4b063/DLlizpeKUn.json';
    }
    if (desc.contains('cloud')) {
      return 'https://lottie.host/1c0d623b-2b45-4b6d-993a-dd7ad20e1c02/WrZoeoFHzj.json';
    }
    if (desc.contains('snow')) {
      return 'https://lottie.host/d5509d6d-90cf-45b0-b204-ba1f3a17e30a/H7g0YoJT62.json';
    }

    return 'https://lottie.host/1c0d623b-2b45-4b6d-993a-dd7ad20e1c02/WrZoeoFHzj.json';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getBackgroundColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter city',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getWeather,
                      child: const Text('Get Weather'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getWeatherByLocation,
                      child: const Text('Use Location'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isLoading) const CircularProgressIndicator(),

              if (_weather != null && !_isLoading)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Lottie.network(
                          weatherAnimationUrl(),
                          width: 150,
                          height: 150,
                        ),
                        Text(
                          _weather!.city,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_weather!.temperature.round()} °C',
                          style: const TextStyle(fontSize: 40),
                        ),
                        Text(_weather!.description),
                        const SizedBox(height: 8),
                        Text('Feels like: ${_weather!.feelsLike.round()} °C'),
                        Text('Humidity: ${_weather!.humidity}%'),
                        Text('Wind: ${_weather!.windSpeed} m/s'),
                        Text('Pressure: ${_weather!.pressure} hPa'),
                      ],
                    ),
                  ),
                ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // NEW: Search History Section
              if (_searchHistory.isNotEmpty) ...[
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Search History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearHistory,
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _searchHistory.map((city) {
                      return ListTile(
                        leading: const Icon(Icons.location_city),
                        title: Text(city),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _searchFromHistory(city),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}