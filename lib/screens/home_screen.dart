import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

       
        if (!_searchHistory.contains(_controller.text)) {
          _searchHistory.insert(0, _controller.text);
          if (_searchHistory.length > 5) _searchHistory.removeLast();
        }
      });
    } catch (e) {
      setState(() => _error = 'City not found');
    } finally {
      setState(() => _isLoading = false);
    }
  }

 
  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _error = 'Location services are disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _error = 'Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _error =
          'Location permissions are permanently denied, cannot request.');
      return null;
    }

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
          position.latitude, position.longitude);
      setState(() => _weather = weather);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  
  List<Color> _getBackgroundColors() {
    if (_weather == null) return [Colors.lightBlue, Colors.lightBlueAccent];

    final desc = _weather!.description.toLowerCase();
    if (desc.contains('clear')) return [Colors.orange, Colors.yellow];
    if (desc.contains('rain')) return [Colors.blue.shade700, Colors.grey.shade600];
    if (desc.contains('snow')) return [Colors.blue.shade100, Colors.white];
    if (desc.contains('cloud')) return [Colors.grey.shade400, Colors.grey.shade800];
    if (desc.contains('storm')) return [Colors.deepPurple, Colors.black];
    if (desc.contains('fog') || desc.contains('mist')) return [Colors.grey.shade300, Colors.grey.shade500];
    return [Colors.lightBlue, Colors.lightBlueAccent];
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
                      child: const Text('Use Current Location'),
                    ),
                  ),
                ],
              ),

           
              if (_searchHistory.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text('Search History', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _searchHistory.length,
                        itemBuilder: (context, index) {
                          final city = _searchHistory[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(city),
                              onPressed: () {
                                _controller.text = city;
                                _getWeather();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              if (_isLoading) const CircularProgressIndicator(),

              
              if (_weather != null && !_isLoading)
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_weather!.city, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${_weather!.temperature.round()} °C', style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text('Description: ${_weather!.description}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Feels like: ${_weather!.feelsLike.round()} °C', style: const TextStyle(fontSize: 16)),
                        Text('Humidity: ${_weather!.humidity} %', style: const TextStyle(fontSize: 16)),
                        Text('Wind: ${_weather!.windSpeed} m/s', style: const TextStyle(fontSize: 16)),
                        Text('Pressure: ${_weather!.pressure} hPa', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
