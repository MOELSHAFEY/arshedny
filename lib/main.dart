// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: splash(),
    );
  }
}

class splash extends StatefulWidget {
  const splash({super.key});

  @override
  State<splash> createState() => _splashState();
}

class _splashState extends State<splash> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
        backgroundColor: const Color.fromARGB(255, 19, 19, 18),
        splashTransition: SplashTransition.scaleTransition,
        splashIconSize: 250,
        splash: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  border: Border.all(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      width: 2)),
              child: Image.asset("imag/shafey.png", height: 180, width: 180),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: const Text(
                "Made By Moelshafey",
                style: TextStyle(
                  color: Color.fromARGB(255, 249, 220, 2),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration:
                  const BoxDecoration(color: Color.fromARGB(222, 11, 254, 165)),
              height: 2.2,
              width: 177,
            ),
          ],
        ),
        nextScreen: const MapScreen());
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  MapType _currentMapType = MapType.normal;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final String _apiKey =
      'AIzaSyCM33nsX09CKNMGbsB5RJdToNNwXbOsm6Q'; // استبدل هذا بمفتاح API الخاص بك

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _checkPermissions() async {
    if (await Permission.location.request().isGranted) {
      _getCurrentLocation();
    }
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentPosition,
      ));
    });
    mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _searchPlace(String type) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition.latitude},${_currentPosition.longitude}&radius=5000&type=$type&key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final places = data['results'].take(5).toList();
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: places.map<Widget>((place) {
                final LatLng destination = LatLng(
                  place['geometry']['location']['lat'],
                  place['geometry']['location']['lng'],
                );
                return ListTile(
                  title: Text(place['name']),
                  subtitle: Text(place['vicinity']),
                  onTap: () {
                    Navigator.pop(context);
                    _drawRoute(destination);
                    _markers.add(Marker(
                      markerId: MarkerId('destination_${place['name']}'),
                      position: destination,
                      infoWindow: InfoWindow(
                        title: place['name'],
                        snippet: place['vicinity'],
                      ),
                    ));
                    _copyLinkToClipboard(destination);
                  },
                );
              }).toList(),
            );
          },
        );
      }
    }
  }

  void _drawRoute(LatLng destination) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      _apiKey,
      PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: const Color.fromARGB(255, 18, 30, 247),
          width: 4,
        ));
      });
    }
  }

  void _copyLinkToClipboard(LatLng destination) {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color.fromARGB(255, 7, 87, 25),
        content: Center(
          child: Text(
              "تم تحديد وجهتك و تم نسخ رابط الاحداثيات ايضا الي الحافظة",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        )));
  }

  void _openTelegramChannel() async {
    final url = Uri.parse(
      'https://t.me/Elshafey_Team',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'لا يمكن فتح الرابط $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
            mapType: _currentMapType,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 110,
            right: 10,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                     backgroundColor: const Color.fromARGB(255, 17, 118, 226),
                  onPressed: _openTelegramChannel,
                  child: const Icon(Icons.telegram, size: 38),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                     backgroundColor: const Color.fromARGB(255, 189, 11, 11),
              //    backgroundColor: const Color.fromARGB(255, 6, 6, 192),
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location, size: 30),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                     backgroundColor: const Color.fromARGB(255, 3, 129, 52),
                  onPressed: _toggleMapType,
                  child: const Icon(Icons.map, size: 38),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                     backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.local_hospital),
                              title: const Text('مستشفى'),
                              onTap: () {
                                Navigator.pop(context);
                                _searchPlace('hospital');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.local_grocery_store),
                              title: const Text('سوبر ماركت'),
                              onTap: () {
                                Navigator.pop(context);
                                _searchPlace('supermarket');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.local_gas_station),
                              title: const Text('محطة وقود'),
                              onTap: () {
                                Navigator.pop(context);
                                _searchPlace('gas_station');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.mosque_rounded),
                              title: const Text('مسجد'),
                              onTap: () {
                                Navigator.pop(context);
                                _searchPlace('mosque');
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Icon(Icons.search,size: 25,color: Color.fromARGB(255, 251, 251, 251)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
