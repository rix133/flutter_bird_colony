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
        updateLocation(value);
      });
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
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
          infoWindow: InfoWindow(title: "Current"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
        ),
      };
    } else {
      markers = {
        Marker(
          markerId: MarkerId("currentLocation"),
          position: currentLatLng,
          infoWindow: InfoWindow(title: "Current"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
        ),
      };
    }
    return super.build(context);
  }
}
