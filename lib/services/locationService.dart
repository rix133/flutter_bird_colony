import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {

  static LocationService instance = LocationService();

  Stream<Position> getPositionStream({LocationAccuracy desiredAccuracy = LocationAccuracy.best, int? distanceFilter, bool? forceAndroidLocationManager}) {
    return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: desiredAccuracy,
        )
    );
  }

  Future<Position> getCurrentPosition({LocationAccuracy desiredAccuracy = LocationAccuracy.best, bool forceAndroidLocationManager = false}) {
    return Geolocator.getCurrentPosition(
        desiredAccuracy: desiredAccuracy,
        forceAndroidLocationManager: forceAndroidLocationManager
    );
  }

  Future<bool> determinePosition(BuildContext context, bool locOK) async {
    if(locOK) return true;
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showDialog(context: context, builder: (BuildContext context){
        return AlertDialog(
          title: Text('Location services are disabled'),
          content: Text('Please enable location services to use this app.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showDialog(context: context, builder: (BuildContext context){
          return AlertDialog(
            title: Text('Location permissions are denied'),
            content: Text('Please enable location permissions to use this app.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      showDialog(context: context, builder: (BuildContext context){
        return AlertDialog(
          title: Text('Location permissions are permanently denied'),
          content: Text('Please enable location permissions to use this app.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }
}
