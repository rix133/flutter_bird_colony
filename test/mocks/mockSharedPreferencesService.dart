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
  LocalSpeciesList speciesList = LocalSpeciesList.fromStringList(["Common gull","Arctic tern"]);
  List<Measure> defaultMeasures = [Measure.note()];
  bool biasedRepeatedMeasures = false;

  String _band = "AA1234";
  String getRecentMetalBand(String species) => _band;
  setRecentMetalBand(String species, String band) => _band = band;

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