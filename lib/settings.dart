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
  bool _isLoggedIn = false;
  SharedPreferencesService? sharedPreferencesService;

  @override
  void initState() {
    super.initState();
    sharedPreferencesService = Provider.of<SharedPreferencesService>(context, listen: false);
    _isLoggedIn = sharedPreferencesService!.isLoggedIn;
    _userName = sharedPreferencesService!.userName;
    _userEmail = sharedPreferencesService!.userEmail;
  }





  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignIn googleSignIn = GoogleSignIn();
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

      if (googleUser == null) {
        // Prompt the user to interactively sign in.
        googleUser = await googleSignIn.signIn();
      }

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

  reset() {
    setState(() {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    sharedPreferencesService?.isLoggedIn = _isLoggedIn;
    sharedPreferencesService?.userName = _userName ?? '';
    sharedPreferencesService?.userEmail = _userEmail ?? '';
    sharedPreferencesService?.autoNextBand = false;
    sharedPreferencesService?.autoNextBandParent = false;
    sharedPreferencesService?.clearAllMetalBands();

    });

  }

  _login() async {
    final user = await signInWithGoogle();
    if (user != null) {
      sharedPreferencesService?.isLoggedIn = true;
      sharedPreferencesService?.userName = user.displayName ?? '';
      sharedPreferencesService?.userEmail = user.email ?? '';
      Navigator.popAndPushNamed(context, '/');
    }
  }

  _logout() async {
    await _googleSignIn.signOut().then((value) =>
        FirebaseAuth.instance.signOut());
    reset();


  }

  List<Widget> getSettings(_isLoggedIn) {
    return _isLoggedIn ? [
      Row(
        children: <Widget>[
          Text('Guess next metal band for chicks:'),
          Switch(
            value: sharedPreferencesService?.autoNextBand ?? false,
            onChanged: (value) {
              sharedPreferencesService?.autoNextBand = value;
            },
          ),
        ],
      ),
    Row(
        children: <Widget>[
          Text('Guess next metal band for parents:'),
          Switch(
            value: sharedPreferencesService?.autoNextBandParent ?? false,
            onChanged: (value) {
              sharedPreferencesService?.autoNextBandParent = value;
            },
          ),
        ],
      ),
    ] : [];
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
            ...getSettings(_isLoggedIn),
          ],
        ),
      ),
    );
  }
}




