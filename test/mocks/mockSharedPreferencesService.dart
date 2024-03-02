import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/firestore/species.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:mockito/mockito.dart';

class MockSharedPreferencesService extends Mock implements SharedPreferencesService {
  bool isAdmin = false;
  bool isLoggedIn = false;
  bool autoNextBand = false;
  bool autoNextBandParent = false;
  LocalSpeciesList speciesList = LocalSpeciesList();
  List<Measure> defaultMeasures = [Measure.note()];
  bool biasedRepeatedMeasures = false;

  double get desiredAccuracy => 4;

  @override
  String get userName => 'Test User';

  @override
  String get userEmail => 'test@example.com';

  @override
  CameraPosition get defaultLocation => CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 270,
    zoom: 16.35,
  );




  // Add other properties and methods as needed
}