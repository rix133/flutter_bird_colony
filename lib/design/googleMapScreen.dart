import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

abstract class GoogleMapScreen extends StatefulWidget {
  final bool autoUpdateLoc;
  final AuthService auth;

  const GoogleMapScreen(
      {Key? key, required this.autoUpdateLoc, required this.auth})
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

  @override
  void initState() {
    super.initState();
    widget.auth.isUserSignedIn().then((value) {
      if (value == false) {
        Navigator.pushReplacementNamed(context, "/settings");
      }
    });
    location.determinePosition(context, _locOK).then((value) => _locOK);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      camPosDefault = sps!.defaultLocation;
      camPosCurrent = CameraPosition(
          target: camPosDefault.target,
          zoom: camPosDefault.zoom,
          bearing: camPosDefault.bearing);
      mapType = sps!.mapType;
      setState(() {
        _googleMapController
            ?.animateCamera(CameraUpdate.newCameraPosition(camPosCurrent));
      });
      if (widget.autoUpdateLoc) {
        _positionStreamSubscription =
            location.getPositionStream().listen((Position position) {
          updateLocation(position);
        });
      }
    });
  }

  void updateLocation(Position value) {
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

  void _updateCameraPosition(
      AsyncSnapshot<Position> snapshot, AsyncSnapshot<CompassEvent> snapshot1) {
    _googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
          snapshot.data?.latitude ?? camPosCurrent.target.latitude,
          snapshot.data?.longitude ?? camPosCurrent.target.longitude,
        ),
        bearing: snapshot1.hasData
            ? snapshot1.data!.heading ?? camPosCurrent.bearing
            : camPosCurrent.bearing,
        zoom: camPosCurrent.zoom,
      )),
    );
    focus.unfocus();
  }

  Widget compassButton() {
    return StreamBuilder<Position>(
      stream: location.getPositionStream(),
      builder: (context, AsyncSnapshot<Position> snapshot) {
        return StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot1) {
            return FloatingActionButton(
              heroTag: "compass",
              onPressed: () => _updateCameraPosition(snapshot, snapshot1),
              child: const Icon(Icons.compass_calibration),
            );
          },
        );
      },
    );
  }

  GestureDetector lastFloatingButton();

  List<Widget> baseFloatingActionButtons() {
    return [
      compassButton(),
      SizedBox(height: 10),
      FloatingActionButton(
        heroTag: "RefreshLocation",
        onPressed: () {
          location
              .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
              .then((value) {
            updateLocation(value);
          });
          focus.unfocus();
        },
        child: const Icon(Icons.my_location),
      ),
      SizedBox(height: 10),
      FloatingActionButton(
        heroTag: "zoomIn",
        onPressed: () {
          _googleMapController
              ?.animateCamera(CameraUpdate.newCameraPosition(camPosDefault));
          focus.unfocus();
        },
        child: const Icon(Icons.zoom_in_map_outlined),
      ),
    ];
  }

  List<Widget> floatingActionButtons() {
    List<Widget> buttons = baseFloatingActionButtons();
    buttons.add(SizedBox(height: 10));
    buttons.add(lastFloatingButton());
    return buttons;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (sps?.showAppBar ?? true)
          ? AppBar(
              title: Text('Nests Map'),
            )
          : null,
      body: SafeArea(
          child: Column(
        children: [
          Flexible(
            child: GoogleMap(
              circles: circle,
              mapToolbarEnabled: false,
              compassEnabled: true,
              markers: markers,
              mapType: mapType,
              zoomControlsEnabled: false,
              initialCameraPosition: camPosCurrent,
              onCameraMove: (position) {
                camPosCurrent = position;
              },
              onMapCreated: (controller) {
                _googleMapController = controller;
                _googleMapController?.animateCamera(
                    CameraUpdate.newCameraPosition(camPosCurrent));
              },
            ),
          ),
        ],
      )),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: floatingActionButtons(),
      ),
    );
  }
}
