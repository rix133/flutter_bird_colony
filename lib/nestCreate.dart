import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakrarahu/design/buildForm.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'species.dart';

class nestCreate extends StatefulWidget {
  const nestCreate({Key? key}) : super(key: key);

  @override
  _nestCreateState createState() => _nestCreateState();
}

class _nestCreateState extends State<nestCreate> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  String get _year => DateTime.now().year.toString();

  final FocusNode _focusNode = FocusNode();
  final nestID = TextEditingController();
  final species = TextEditingController();
  final remark = TextEditingController();

  static String _displayStringForOption(Species option) => option.english;
  var _asukoht;
  bool signed = false;
  var accuracy = "loading...";
  var coords;
  var exists;
  var username;
  var sihtkoht;

  var map = <String, dynamic>{};

  void _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    print(position.accuracy);
    if (mounted) {
      setState(() {
        _asukoht = position;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nestID.dispose();
    species.dispose();
    remark.dispose();
    super.dispose();
  }

  void addItem(value, String key) {
    if (value != null) {
      map.addEntries({key: value}.entries);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
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
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Widget build(BuildContext context) {
    final data = (ModalRoute.of(context)?.settings.arguments??{}) as Map;
    data.containsKey("nestid")?nestID.text=(int.parse(data["nestid"])+1).toString():null;
    data.containsKey("species")?species.text=data["species"]:null;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        signed = false;
      } else {
        print('User is signed in as ' + user.displayName.toString());
        signed = true;
        username = user.displayName.toString();
      }
    });

    CollectionReference pesa = FirebaseFirestore.instance.collection(_year);
    CollectionReference recent =
        FirebaseFirestore.instance.collection('recent');
    final Stream<QuerySnapshot> _idStream =
        FirebaseFirestore.instance.collection('recent').snapshots();

    //pesa.get().then((value) => value.docs.forEach((element) {print(element.id);}));

    if (_asukoht == null) {
      _getCurrentLocation();
      print("Receiving initial location data");
    } else {
      accuracy = _asukoht.accuracy.toStringAsFixed(2) + "m";
      print(_asukoht.accuracy.runtimeType);
      coords = GeoPoint(_asukoht.latitude, _asukoht.longitude);
    }

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StreamBuilder<QuerySnapshot>(
                  stream: _idStream,
                  builder: (context, snapshot) {
                    if (!mounted) return SizedBox();
                    return Column(
                      children: [
                        Text(snapshot.data?.docs.where((element) => element.id=="kalakas").first.get("nestid").toString() ??
                            ""),
                        Text(snapshot.data?.docs.where((element) => element.id=="muu").first.get("nestid").toString() ??
                            ""),
                      ],
                    );
                  }),
              /*Expanded(
                child: StreamBuilder<QuerySnapshot>(
                    stream: _idStream,
                    builder:(context, snapshot) {return
                      Autocomplete(
                        fieldViewBuilder: Text,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                        return [snapshot.data?.docs[0].get("nestid").toString()??"a"].where((element) {return element.contains(textEditingValue.text.toLowerCase());});
                      });
                    }
                ),
              ),*/
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                    child: buildForm(context, "enter nest ID", null, nestID,  true)),
                //Icon(Icons.check_circle,color: Colors.green,size: 40,)
              ]),
              RawAutocomplete<Species>(
                displayStringForOption: _displayStringForOption,
                focusNode: _focusNode,
                textEditingController: species,
                onSelected: (selectedString) {
                  print(selectedString);
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Scaffold(
                    body: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(
                              option.english.toString(),
                              textAlign: TextAlign.center,
                            ),
                            textColor: Colors.black,
                            contentPadding: EdgeInsets.all(0),
                            visualDensity: VisualDensity.comfortable,
                            tileColor: Colors.orange[300],
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                              height: 0,
                            ),
                        itemCount: options.length),
                  );
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    textAlign: TextAlign.center,
                    controller: textEditingController,
                    decoration: InputDecoration(
                      labelText: "species",
                      hintText: "enter species",
                      fillColor: Colors.orange,
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: (BorderSide(color: Colors.indigo))),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(
                          color: Colors.deepOrange,
                          width: 1.5,
                        ),
                      ),
                    ),
                    focusNode: focusNode,
                    onFieldSubmitted: (String value) {
                      onFieldSubmitted();
                      print('You just typed a new entry  $value');
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
                optionsBuilder: (TextEditingValue textEditingValue) {
                  /*if (textEditingValue.text == '') {
                    return const Iterable<SpeciesList>.empty();
                  }*/
                  return SpeciesList.english.where((Species option) {
                    return option
                        .toString()
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
              ),
              SizedBox(height: 15),
              buildForm(context, "remark", null, remark),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      new ElevatedButton.icon(
                          onPressed: () {_getCurrentLocation();
                          },
                          icon: Icon(
                            Icons.my_location,
                            color: Colors.black87,
                            size: 40,
                          ),
                          label: Text("location")),
                      Text("Accuracy: " + accuracy),
                    ],
                  ),
                  //Location nupp+täpsusinfo
                  new ElevatedButton.icon(
                      onPressed: () async {
                        var time = DateTime.now();
                        if (signed != false) {
                          sihtkoht = nestID.text;
                          addItem(coords, "coordinates");
                          addItem(accuracy, "accuracy");
                          addItem(username, "responsible");
                          addItem(species.text, "species");
                          addItem(remark.text, "remark");
                          addItem(time, "last_modified");
                          addItem(time, "discover_date");
                          addItem([], "experiments");
                          addItem(sihtkoht, "id");
                          exists = await pesa.doc(sihtkoht).get();
                          if (exists.exists == false && accuracy!="loading...") {
                            print("ei eksisteeri");
                            pesa.doc(sihtkoht).set(map);
                            pesa
                                .doc(sihtkoht)
                                .collection("changelog")
                                .doc(time.toString())
                                .set(map)
                                .then((value) => pesa.doc(sihtkoht).update({"discover_date": time}))
                                .catchError((error) => print("Failed: $error"));
                            Navigator.pop(context);
                            Navigator.pushNamed(context, "/nestManage",
                                arguments: {
                                  "sihtkoht": sihtkoht,
                                  "species": species.text,
                                });
                            if (species.text == "Common Gull") {
                              recent.doc("kalakas").set({"nestid": sihtkoht});
                            } else if(sihtkoht.toString().contains("x")?false:true){
                              recent.doc("muu").set({"nestid": sihtkoht});
                            }
                          } else {
                            showDialog<String>(
                              barrierColor: Colors.black,
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                contentTextStyle:
                                    TextStyle(color: Colors.black),
                                titleTextStyle: TextStyle(color: Colors.red),
                                title: const Text('Nest already exists'),
                                content: const Text(
                                    'Do you want to navigate to the selected nest?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        {Navigator.pop(context, 'Cancel')},
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => {
                                      Navigator.pop(context, 'OK'),
                                      Navigator.pushNamed(
                                          context, "/nestManage",
                                          arguments: {
                                            "sihtkoht": sihtkoht,
                                            "species": species.text,
                                          })
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } //ALERTDIALOG
                        } else {
                          signInWithGoogle();
                        }
                      },
                      icon: Icon(
                        Icons.save,
                        color: Colors.black87,
                        size: 45,
                      ),
                      label: Text("add nest")),
                  //save button
                  //Text(pesa.where("species",isEqualTo: "Common Gull").orderBy(field))
                ],
              ), //asukoht ja save nupp
            ],
          ),
        ),
      ),
    );
  }
}
