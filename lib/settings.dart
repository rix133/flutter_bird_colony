import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? _userName;
  String? _userEmail;
  int _selectedYear = DateTime.now().year;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    final sharedPreferencesService = Provider.of<SharedPreferencesService>(context, listen: false);
    _selectedYear = sharedPreferencesService.selectedYear;
    _isLoggedIn = sharedPreferencesService.isLoggedIn;
    _userName = sharedPreferencesService.userName;
    _userEmail = sharedPreferencesService.userEmail;
  }



  _saveSelectedYear() async {
    final sharedPreferencesService = Provider.of<SharedPreferencesService>(context, listen: false);
    sharedPreferencesService.selectedYear = _selectedYear;
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return (await FirebaseAuth.instance.signInWithCredential(credential)).user;
    } catch (e) {
      print('Sign in failed: $e');
      print(
          'Likely SHA-1 fingerprint is missing from https://console.cloud.google.com/apis/credentials?project=kakrarahu');
      //sign out from google
      await GoogleSignIn().signOut();
      // Create a new credential
      
      return null;
    }
  }

  _login() async {
    final user = await signInWithGoogle();
    if (user != null) {
      final sharedPreferencesService = Provider.of<SharedPreferencesService>(context, listen: false);
      sharedPreferencesService.isLoggedIn = true;
      sharedPreferencesService.userName = user.displayName ?? '';
      sharedPreferencesService.userEmail = user.email ?? '';
      Navigator.popAndPushNamed(context, '/');
    }
  }

  _logout() async {
    await _googleSignIn.signOut().then((value) =>
        FirebaseAuth.instance.signOut());
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    final sharedPreferencesService = Provider.of<SharedPreferencesService>(context, listen: false);
    sharedPreferencesService.isLoggedIn = _isLoggedIn;
    sharedPreferencesService.userName = _userName ?? '';
    sharedPreferencesService.userEmail = _userEmail ?? '';
    setState(() {

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (_isLoggedIn)
              Text('Logged in as $_userName ($_userEmail)'),
            SizedBox(height: 5),
            ElevatedButton(
              child: Text(_isLoggedIn ? 'Logout' : 'Login with Google'),

              onPressed: _isLoggedIn ? _logout : _login,
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: "Select breeding year",
                filled: true,
                fillColor: Colors.white,
              ),
              value: _selectedYear,
              items: List.generate(DateTime.now().year - 2022 + 1, (index) {
                final year = 2022 + index;
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: TextStyle(color: Colors.black), // Set the text color here
                  ),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedYear = value!;
                });
                _saveSelectedYear();
              },
            ),
          ],
        ),
      ),
    );
  }
}




