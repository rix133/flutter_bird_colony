import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseOptions, FirebaseApp, defaultFirebaseAppName;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main class for persisting a Firebase environment in [SharedPreferences]
class FirebaseOptionsSelector {
  static const _storageKey = 'environment';
  static Map<String, FirebaseOptions> _availableOptions = {};
  static String _selectedKey = 'testing';

  /// Map environment names to [FirebaseOptions]
  static Map<String, FirebaseOptions> get availableOptions => _availableOptions;

  /// Name of current environment
  static String get selectedKey => _selectedKey;

  /// Read environment selection from [SharedPreferences] and run
  /// [Firebase.initializeApp] with the selected [FirebaseOptions]
  static Future<FirebaseApp> initialize(String productionKey,
      Map<String, FirebaseOptions> availableOptions) async {
    _availableOptions = availableOptions;

    return (Firebase.initializeApp(
      options: availableOptions[productionKey],
      name: productionKey,
    ));
  }

  /// Get the current selection from [SharedPreferences]
  static Future<String> getCurrentSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey);
    return availableOptions.keys.firstWhere((element) => element == value, orElse: () => 'testing');
  }

  /// Shortcut to use [FirebaseOptionsBanner] as the builder for [MaterialApp]
  static Widget materialAppBuilder(BuildContext context, Widget? child) =>
      FirebaseOptionsBanner(child: child!);

  /// Select a different environment for the next time the app starts
  static Future<void> select(String newValue) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_storageKey, newValue);
  }
}

// Widget that shows a banner with the environment name,
/// unless the app is using the production environment
class FirebaseOptionsBanner extends StatelessWidget {
  /// The widget to show behind the banner.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  const FirebaseOptionsBanner({key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
      return child;
  }
}
