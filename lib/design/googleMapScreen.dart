import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

abstract class GoogleMapScreen extends StatefulWidget {
  final autoUpdateLoc;

  const GoogleMapScreen({Key? key, required this.autoUpdateLoc})
      : super(key: key);

  get firestoreInstance => null;

  @override
  State<GoogleMapScreen> createState();
}

abstract class GoogleMapScreenState extends State<GoogleMapScreen> {
  CameraPosition camPosCurrent = CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 0,
    zoom: 6,
  );
  CameraPosition camPosDefault = CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 0,
    zoom: 6,
  );
  GeoPoint coordinates = GeoPoint(58.766218, 23.430432);
  double accuracy = 999999.0;

  SharedPreferencesService? sps;
  MapType mapType = MapType.satellite;
  GoogleMapController? _googleMapController;

  Set<Circle> circle = {
    Circle(
      circleId: CircleId("myLocEmpty"),
    )
  };
  final focus = FocusNode();
  Set<Marker> markers = {};
  bool _locOK = false;

  StreamSubscription<Position>? _positionStreamSubscription;
  LocationService location = LocationService.instance;
  AuthService auth = AuthService.instance;

  @override
  void initState() {
    super.initState();
    auth.isUserSignedIn().then((value) {
      if (value == false) {
        Navigator.pushReplacementNamed(context, "/settings");
      }
    });
    location.determinePosition(context, _locOK).then((value) => _locOK);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      camPosDefault = sps!.defaultLocation;
      camPosCurrent = sps!.defaultLocation;
      mapType = sps!.mapType;
      if (widget.autoUpdateLoc) {
        _positionStreamSubscription =
            location.getPositionStream().listen((Position position) {
          _updateLocation(position);
        });
      }
    });
  }

  _updateLocation(Position value) {
    accuracy = value.accuracy;
    coordinates = GeoPoint(value.latitude, value.longitude);
    camPosCurrent = CameraPosition(
      target: LatLng(value.latitude, value.longitude),
      bearing: camPosCurrent.bearing,
      zoom: camPosCurrent.zoom,
    );
    setState(() {
      circle = {
        Circle(
          circleId: CircleId("myLoc"),
          radius: value.accuracy,
          center: camPosCurrent.target,
          strokeColor: Colors.orange,
        )
      };
    });
    _googleMapController
        ?.animateCamera(CameraUpdate.newCameraPosition(camPosCurrent));
  }

  GestureDetector lastFloatingButton();

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _googleMapController?.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Flexible(
            child: GoogleMap(
              circles: circle,
              mapToolbarEnabled: false,
              compassEnabled: true,
              markers: markers,
              mapType: mapType,
              zoomControlsEnabled: false,
              initialCameraPosition: camPosDefault,
              onCameraMove: (position) {
                camPosCurrent = position;
              },
              onMapCreated: (controller) => _googleMapController = controller,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "RefreshLocation",
            onPressed: () {
              location
                  .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
                  .then((value) {
                _updateLocation(value);
              });
              focus.unfocus();
            },
            child: const Icon(Icons.my_location),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoomIn",
            onPressed: () {
              _googleMapController?.animateCamera(
                  CameraUpdate.newCameraPosition(camPosDefault));
              focus.unfocus();
            },
            child: const Icon(Icons.zoom_in_map_outlined),
          ),
          SizedBox(height: 10),
          lastFloatingButton(),
        ],
      ),
    );
  }
}
