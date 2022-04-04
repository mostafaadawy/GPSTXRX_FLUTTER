import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'location_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Dynamic links
        ChangeNotifierProvider(
          create: (_) => LocationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Adawy Projects ',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
        ),
        debugShowCheckedModeBanner: false,
        home: const MyHomePage(
          title: 'Adawy Projects',
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Location location = Location();
  final Completer<GoogleMapController> _controller = Completer();
  bool isFechted = false;
  LocationData? currentLocation;
  LocationData? previousLocation;
  bool? _serviceEnabled;
  PermissionStatus? _permissionGranted;
  LocationData? initialLocationData;
  List<Marker> markers = <Marker>[];

  Future<void> initLocation() async {
    if (isFechted) {
      return;
    }
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled!) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    initialLocationData = await location.getLocation();
    currentLocation = initialLocationData;
    previousLocation = currentLocation;

    isFechted = true;
  }

  @override
  void initState() {
    location.enableBackgroundMode(enable: true);
    location.onLocationChanged.listen((LocationData currentLocationValue) {
      print('Listening.........................');
      if (previousLocation != null) {
        if (previousLocation!.latitude == currentLocationValue.latitude &&
            previousLocation!.longitude == currentLocationValue.longitude) {
          print('Same coordinates ........');
          return;
        }
      }

      // Use current location

      Provider.of<LocationProvider>(context, listen: false)
          .updateCoordinatesInFirebase(
        context: context,
        latitude: currentLocationValue.latitude.toString(),
        longitude: currentLocationValue.longitude.toString(),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: FutureBuilder(
        future: initLocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return StreamBuilder<LocationData>(
              stream: location.onLocationChanged,
              builder: (
                BuildContext context,
                AsyncSnapshot<LocationData> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.connectionState == ConnectionState.active ||
                    snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        children: [
                          const Text(
                            'An error occured',
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              snapshot.error.toString(),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasData) {
                    markers.clear();
                    markers.add(
                      Marker(
                        markerId: MarkerId(UniqueKey().toString()),
                        position: LatLng(
                          snapshot.data!.latitude!,
                          snapshot.data!.longitude!,
                        ),
                        infoWindow: const InfoWindow(
                          title: 'Current Location',
                        ),
                      ),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'My Current Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Latitude == ${snapshot.data!.latitude}\nLongitude == ${snapshot.data!.longitude}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        const Divider(
                          indent: 10,
                          endIndent: 10,
                        ),
                        Expanded(
                          child: GoogleMap(
                            mapType: MapType.normal,
                            markers: Set<Marker>.of(markers),
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                snapshot.data!.latitude!,
                                snapshot.data!.longitude!,
                              ),
                              zoom: 18,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Text('Empty data');
                  }
                } else {
                  return Text('State: ${snapshot.connectionState}');
                }
              },
            );
          }
        },
      ),
    );
  }
}
