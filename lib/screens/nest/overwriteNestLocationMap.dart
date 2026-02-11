import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/googleMapScreen.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OverwriteNestLocationMap extends GoogleMapScreen {
  const OverwriteNestLocationMap({Key? key, required auth})
      : super(key: key, auth: auth, autoUpdateLoc: false);

  @override
  _OverwriteNestLocationMapState createState() =>
      _OverwriteNestLocationMapState();
}

class _OverwriteNestLocationMapState extends GoogleMapScreenState {
  Nest? _nest;
  GeoPoint? _nestCoordinates;

  void _updateMarkers() {
    final LatLng currentLatLng =
        LatLng(coordinates.latitude, coordinates.longitude);
    if (_nestCoordinates != null) {
      markers = {
        Marker(
          markerId: MarkerId("nestLocation"),
          position:
              LatLng(_nestCoordinates!.latitude, _nestCoordinates!.longitude),
          infoWindow: InfoWindow(title: "Nest ${_nest?.name ?? ""}".trim()),
        ),
        Marker(
          markerId: MarkerId("currentLocation"),
          position: currentLatLng,
          infoWindow: InfoWindow(title: "Selected Location"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    } else {
      markers = {
        Marker(
          markerId: MarkerId("currentLocation"),
          position: currentLatLng,
          infoWindow: InfoWindow(title: "Selected Location"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var map = ModalRoute.of(context)?.settings.arguments;
      if (map != null) {
        map = map as Map<String, dynamic>;
        _nest = map["nest"] as Nest?;
        _nestCoordinates = _nest?.coordinates;
      }
      location
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .then((value) {
        setState(() {
          updateLocation(value);
          _updateMarkers();
        });
      });
    });
  }

  @override
  void onMapTap(LatLng position) {
    updateLocation(Position(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: 0,
      timestamp: DateTime.now(),
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ));

    setState(() {
      _updateMarkers();
    });
  }

  @override
  GestureDetector lastFloatingButton() {
    return GestureDetector(
      child: FloatingActionButton(
        key: Key("overwriteLocationButton"),
        heroTag: "overwriteNestLocation",
        onPressed: () {
          Navigator.pop(context, <String, dynamic>{
            "coordinates": coordinates,
            "accuracy": accuracy,
          });
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _locationButton() {
    return FloatingActionButton(
      heroTag: "RefreshLocation",
      onPressed: () {
        location
            .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
            .then((value) {
          updateLocation(value);
          setState(() {
            _updateMarkers();
          });
        });
        focus.unfocus();
      },
      child: const Icon(Icons.my_location),
    );
  }

  @override
  List<Widget> baseFloatingActionButtons() {
    return [
      compassButton(),
      SizedBox(height: 10),
      _locationButton(),
      SizedBox(height: 10),
      // Get the zoom button from parent
      super.baseFloatingActionButtons()[4],
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Don't recreate markers on every build - they are managed by _updateMarkers()
    return super.build(context);
  }
}
