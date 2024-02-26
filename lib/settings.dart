import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/defaultSettings.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'models/species.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? _userName;
  String? _userEmail;
  String? _userPassword;
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
              content: SingleChildScrollView(child:Column(
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
              )),
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

  _goToEditSpecies() {
    return _isAdmin ? Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/listSpecies');
          },
          label: Padding(child:Text('Manage species'), padding: EdgeInsets.all(10)),
          icon: Icon(Icons.folder),
        ),
      ],
    ) : Container();
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

  Future<User?> signInWithNewEmail() async {
    if(_userEmail == null || _userPassword == null) return null;
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _userEmail!,
          password: _userPassword!
      );
      userCredential.user!.updateDisplayName(_userEmail!.split('@').first);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Weak password', style: TextStyle(color: Colors.red)),
              content: Text('The password provided is too weak.', style: TextStyle(color: Colors.black),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else if (e.code == 'email-already-in-use') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Email already in use', style: TextStyle(color: Colors.red)),
              content: Text('The account already exists for that email.', style: TextStyle(color: Colors.black),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return null;
    }
  }

  Future<User?> signInWithExistingEmail() async {
    if(_userEmail == null || _userPassword == null) return null;
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _userEmail!,
          password: _userPassword!
      );
      userCredential.user!.updateDisplayName(_userEmail!.split('@').first);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('User not found', style: TextStyle(color: Colors.red)),
              content: Text('No user found for that email.', style: TextStyle(color: Colors.black),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else if (e.code == 'wrong-password') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Wrong password', style: TextStyle(color: Colors.red)),
              content: Text('Wrong password provided for that user.', style: TextStyle(color: Colors.black),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return null;
    }
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
    _updateSpeciesList();
  }

  _updateSpeciesList() {
    FirebaseFirestore.instance.collection('settings').doc('default').collection("species").get().then((value) {
      List<Species> speciesList = value.docs.map((e) => Species.fromDocSnapshot(e)).toList();
      sharedPreferencesService?.speciesList = LocalSpeciesList.fromSpeciesList(speciesList);
    });
  }


  Future<bool> _login(String loginType) async {
    User? user;
    if (loginType == 'google') {
      user = await signInWithGoogle();
    }
     if(loginType == 'existingEmail') {
       if(_userEmail != null || _userPassword != null) {
          user = await signInWithExistingEmail();
          print(user?.email);
        }
     }
     if(loginType == 'newEmail') {
       user = await signInWithNewEmail();
     }

    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.email).get().then((value) async {
        if (value.exists) {
          _isAdmin = value['isAdmin'];
          sharedPreferencesService?.isAdmin = value['isAdmin'];
          sharedPreferencesService?.isLoggedIn = true;
          sharedPreferencesService?.userName = user!.displayName ?? '';
          sharedPreferencesService?.userEmail = user!.email ?? '';
          _setDefaultSettings();
          //pop all and go to homepage
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          return true;
        } else {
          int userCount = await FirebaseFirestore.instance.collection('users').get().then((value) => value.docs.length);
          //if no users, the first user is admin
          if (userCount == 0) {
            FirebaseFirestore.instance.collection('users').doc(user!.email).set({'isAdmin': true});
            sharedPreferencesService?.isAdmin = true;
            sharedPreferencesService?.isLoggedIn = true;
            sharedPreferencesService?.userName = user.displayName ?? '';
            sharedPreferencesService?.userEmail = user.email ?? '';
            _setDefaultSettings();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            return true;
          } else {
            await _googleSignIn.signOut().then((value) =>
                FirebaseAuth.instance.signOut());
            reset();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Not authorized', style: TextStyle(color: Colors.red)),
                  content: Text('You are not authorized to use this app, request access from the admin(s).', style: TextStyle(color: Colors.black),),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
            return false;
          }
        }
      });
    }
    else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Login failed', style: TextStyle(color: Colors.red)),
            content: Text('Login failed, please try again.', style: TextStyle(color: Colors.black),),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return false;
    }
    return false;
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
  _openEmailLoginDialog() {
    bool _disable = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Opacity(
                opacity: _disable ? 0.5 : 1,
                child:
                AbsorbPointer(
                    absorbing: _disable,
                    child:AlertDialog(
              title: Text('Login with email', style: TextStyle(color: Colors.black)),
              content: SingleChildScrollView(child:

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.deepPurpleAccent)),
                    onChanged: (value) {
                      _userEmail = value;
                    },
                  ),
                  TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(hintText: 'Password', hintStyle: TextStyle(color: Colors.deepPurpleAccent)),
                    onChanged: (value) {
                      _userPassword = value;
                    },
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _disable = true;
                      });
                      await _login('existingEmail');
                      setState(() {
                        _disable = false;
                      });
                      Navigator.pop(context);
                    },
                    label: Padding(child:Text('Login'), padding: EdgeInsets.all(10)),
                    icon: Icon(Icons.account_circle),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _disable = true;
                      });
                      await _login('newEmail');
                      setState(() {
                        _disable = false;
                      });
                      Navigator.pop(context);
                    },
                    label: Padding(child:Text('Create new account'), padding: EdgeInsets.all(10)),
                    icon: Icon(Icons.account_circle),
                  ),
                ],
              )),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            )));
          },
        );
      },
    );
  }


  List<Widget> getSettings(_isLoggedIn) {
    return _isLoggedIn ? [
      Row(
        children: <Widget>[
          Text('Auto set guessed metal band for chicks:'),
          Switch(
            value: sharedPreferencesService?.autoNextBand ?? false,
            onChanged: (value) {
              sharedPreferencesService?.autoNextBand = value;
              setState(() {

              });
            },
          ),
        ],
      ),
      SizedBox(height: 10),
    Row(
        children: <Widget>[
          Text('Auto set guessed metal band for parents:'),
          Switch(
            value: sharedPreferencesService?.autoNextBandParent ?? false,
            onChanged: (value) {
              sharedPreferencesService?.autoNextBandParent = value;
              setState(() {

              });
            },
          ),
        ],
      ),
      SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed:  _updateSpeciesList,
            label: Padding(child:Text('Refresh autocomplete species'), padding: EdgeInsets.all(10)),
            icon: Icon(Icons.refresh),
          ),
        ],
      )
    ] : [];
  }

  Widget _getLoginButtons() {
    return !_isLoggedIn ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _login('google');
          },
          label: Padding(child:Text('Login with Google'), padding: EdgeInsets.all(10)),
          icon: Icon(Icons.account_circle),
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            _openEmailLoginDialog();
          },
          label: Padding(child:Text('Login with email'), padding: EdgeInsets.all(10)),
          icon: Icon(Icons.email),
        ),
        SizedBox(height: 10),
      ],
    ) : //make logout button
    ElevatedButton.icon(
      onPressed: _logout,
      label: Padding(child:Text('Logout'), padding: EdgeInsets.all(10)),
      icon: Icon(Icons.account_circle),
    );
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
            _getLoginButtons(),
            SizedBox(height: 20),
            ...getSettings(_isLoggedIn),
            SizedBox(height: 20),
            _getAllowedUsers(),
            SizedBox(height: 20),
            _goToEditDefaultSettings(),
            SizedBox(height: 20),
            _goToEditSpecies(),

          ],
        ),
      ),
    ));
  }
}




