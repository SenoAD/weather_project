import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherScreen(),
    );
  }
}

String getStaticMapImageUrl({
  required String apiKey,
  required double latitude,
  required double longitude,
  required int zoom,
  required String size,
  required String mapType,
  double? markerLatitude,
  double? markerLongitude,
  String markerColor = 'red',
}) {
  final baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
  final parameters = {
    'center': '$latitude,$longitude',
    'zoom': zoom.toString(),
    'size': size,
    'maptype': mapType,
    'key': apiKey,
    if (markerLatitude != null && markerLongitude != null)
      'markers': 'color:$markerColor|$markerLatitude,$markerLongitude',
  };

  final queryString = Uri(queryParameters: parameters).query;
  final url = '$baseUrl?$queryString';

  return url;
}


class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _longitude = 'Loading...';
  String _weather = 'Loading...';
  String _latitude = 'Loading...';
  String _townname = 'Loading...';
  String _image = 'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg';
  final apiKey = ''; // Replace with your API key
  final zoom = 14;
  final size = '400x300';
  final mapType = 'roadmap';
  final markerColor = 'red';

  @override
  void initState() {
    super.initState();
    _updateWeather();
  }

  Future<void> _updateWeather() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    final response = await http.get(
        Uri.parse('http://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=c36d00a1ade6f97e5f7d9861c3dff92c'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String weather = data['weather'][0]['description'];

      final responseTownName = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key='));

      if (responseTownName.statusCode == 200) {
        final decodedData = json.decode(responseTownName.body);
        final results = decodedData['results'] as List<dynamic>;

        if (results.isNotEmpty) {
          final townComponent = results[0]['address_components'] as List<dynamic>;
          final townName = townComponent[4];

          if (townName != null) {
            setState(() {
              _townname = townName['long_name'];
            });
          }
        }
      } else {
        setState(() {
          _townname = 'error';
        });
      }

      setState(() {
        _latitude = '${position.latitude}';
        _longitude = '${position.longitude}';
        _weather = weather;
        final imageUrl = getStaticMapImageUrl(
          apiKey: apiKey,
          latitude: position.latitude,
          longitude: position.longitude,
          zoom: zoom,
          size: size,
          mapType: mapType,
          markerLatitude: position.latitude,
          markerLongitude: position.longitude,
          markerColor: markerColor,
        );
        _image = imageUrl;
      });
    } else {
      setState(() {
        _latitude = 'Failed to load data.';
        _longitude = 'Failed to load data.';
        _weather = 'Failed to load weather data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Longitude : $_longitude'),
            Text('Latitude : $_latitude'),
            Text('Town : $_townname'),
            Text('Current Weather: $_weather'),
            Image.network('$_image'),
          ],
        ),
      ),
    );
  }
}