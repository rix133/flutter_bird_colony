import 'package:kakrarahu/models/species.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:mockito/mockito.dart';

class MockSharedPreferencesService extends Mock implements SharedPreferencesService {
  bool isAdmin = false;
  bool isLoggedIn = false;
  bool autoNextBand = false;
  bool autoNextBandParent = false;
  LocalSpeciesList speciesList = LocalSpeciesList();

  @override
  String get userName => 'Test User';

  @override
  String get userEmail => 'test@example.com';




  // Add other properties and methods as needed
}