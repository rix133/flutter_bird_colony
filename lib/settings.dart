import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/defaultSettings.dart';
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
  bool _isAdmin = false;
  List<String> _allowedUsers = [];
  SharedPreferencesService? sharedPreferencesService;

  @override
  void initState() {
    super.initState();
    sharedPreferencesService = Provider.of<SharedPreferencesService>(context, listen: false);
    _isLoggedIn = sharedPreferencesService!.isLoggedIn;
    _userName = sharedPreferencesService!.userName;
    _userEmail = sharedPreferencesService!.userEmail;
    _isAdmin = sharedPreferencesService!.isAdmin;
    if(_isAdmin) {
      FirebaseFirestore.instance.collection('users').get().then((value) {
        value.docs.forEach((element) {
          _allowedUsers.add(element.id);
        });
        setState(() {

        });
      });
    }
  }

  Future<String> _addUserByEmail() async {
    String email = '';
    String? warning;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('New user', style: TextStyle(color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.deepPurpleAccent)),
                    onChanged: (value) {
                      email = value;
                    },
                  ),
                  if (warning != null)
                    Text(
                      warning ?? '',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    email = '';
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (email.isNotEmpty &&
                        !_allowedUsers.contains(email) &&
                        RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9_%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(email)) {
                      FirebaseFirestore.instance.collection('users').doc(email).set({'isAdmin': false});
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        warning = 'Invalid email or already added';
                      });
                    }
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
    return email;
  }


  Widget _getAllowedUsers() {
    return _isAdmin ? Column(
      children: [
        Text('Allowed users:'),
        ..._allowedUsers.map((e) => Text(e)),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () async {
            await _addUserByEmail().then((value) {
              if (value.isNotEmpty) {
                _allowedUsers.add(value);
                setState(() { });
              }
            });
          },
          label: Padding(child:Text('Add user'), padding: EdgeInsets.all(10)),
          icon: Icon(Icons.add),
        ),
      ],
    ) : Container();
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
    _isAdmin = false;
    _userName = '';
    _userEmail = '';
    sharedPreferencesService?.clearAll();

    });

  }
  _setDefaultSettings() {
    FirebaseFirestore.instance.collection('settings').doc('default').get().then((value) {
      if (value.exists) {
        DefaultSettings defaultSettings = DefaultSettings.fromDocSnapshot(value);
        sharedPreferencesService?.setFromDefaultSettings(defaultSettings);

      }
    });
  }


  _login() async {
    final user = await signInWithGoogle();
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.email).get().then((value) {
        if (value.exists) {
          _isAdmin = value['isAdmin'];
          sharedPreferencesService?.isAdmin = value['isAdmin'];
          sharedPreferencesService?.isLoggedIn = true;
          sharedPreferencesService?.userName = user.displayName ?? '';
          sharedPreferencesService?.userEmail = user.email ?? '';
          _setDefaultSettings();
          if(!_isAdmin) {
            Navigator.popAndPushNamed(context, '/');
          }
          else {
            setState(() {
              _isLoggedIn = true;
              _userName = user.displayName;
              _userEmail = user.email;
            });
          }
        } else {
          AlertDialog(
            title: Text('Not authorized'),
            content: Text('You are not authorized to use this app, request access from the admin.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        }
      });


    }
  }

  Widget _goToEditDefaultSettings() {
    return _isAdmin ? Row(
      mainAxisAlignment: MainAxisAlignment.center,
        children:[ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, '/editDefaultSettings');
      },
      label: Text('Edit default settings'),
      icon: Icon(Icons.settings),
    )]) : Container();
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
        child: SingleChildScrollView(
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
            SizedBox(height: 20),
            _getAllowedUsers(),
            SizedBox(height: 20),
            _goToEditDefaultSettings(),

          ],
        ),
      ),
    ));
  }
}




