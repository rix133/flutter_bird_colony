import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/species.dart';

class Individual extends StatefulWidget {
  const Individual({Key? key}) : super(key: key);

  @override
  State<Individual> createState() => _IndividualState();
}

class _IndividualState extends State<Individual> {
  TextEditingController band_id_letters = TextEditingController();
  TextEditingController band_id_numbers = TextEditingController();
  TextEditingController nestID = TextEditingController();
  TextEditingController eggNr = TextEditingController();
  TextEditingController species = TextEditingController();
  TextEditingController age = TextEditingController();
  FocusNode _focusNode = FocusNode();
  String get _year => DateTime.now().year.toString();

  static String _displayStringForOption(SpeciesList option) => option.english;
  var username;
  var uid;

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        username = user.displayName.toString();
        if (user.uid != uid) {
          print(user.uid);
          setState(() {
            uid = user.uid;
          });
        }
      }
    });
    var map = ModalRoute.of(context)?.settings.arguments as Map;
    species.text = map["species"] ?? "";
    eggNr.text = map["muna_nr"] ?? "";
    nestID.text = map["pesa"] ?? "";
    age.text = map["age"] ?? "";

    CollectionReference nest = FirebaseFirestore.instance.collection(_year);
    CollectionReference recent_band = FirebaseFirestore.instance
        .collection("recent")
        .doc("band")
        .collection(uid ?? "not logged");
    CollectionReference birds = FirebaseFirestore.instance.collection("Birds");
    if (species.text == "Common Gull") {
      band_id_letters.text = "UA";
      recent_band.doc("UA").get().then((value) => band_id_numbers.text =
          value.exists ? (value.get("UA") + 1).toString() : "");
    }
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
            child: Column(
              children: [
                Text(
                  "new band",
                  style: TextStyle(
                      fontSize: 50,
                      letterSpacing: -5,
                      decoration: TextDecoration.underline),
                ),
                SizedBox(height: 25),
                RawAutocomplete<SpeciesList>(
                  displayStringForOption: _displayStringForOption,
                  focusNode: _focusNode,
                  textEditingController: species,
                  onSelected: (selectedString) {
                    recent_band.doc("UA").get().then((value) {
                      if (selectedString.english == "Common Gull") {
                        band_id_letters.text = "UA";
                        band_id_numbers.text = value.exists
                            ? (value.get("UA") + 1).toString()
                            : "";
                      }
                    });
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Scaffold(
                      resizeToAvoidBottomInset: false,
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
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.blue,
                        labelText: "species",
                        labelStyle:
                            TextStyle(color: Colors.white, fontSize: 30),
                        hintText: "insert species name",
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: (BorderSide(color: Colors.white))),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(
                            color: Colors.white,
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
                    if (textEditingValue.text == '') {
                      return const Iterable<SpeciesList>.empty();
                    }
                    return Species.english.where((SpeciesList option) {
                      return option
                          .toString()
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextFormField(
                        controller: band_id_letters,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.blue,
                          labelText: "letters",
                          labelStyle:
                              TextStyle(color: Colors.white, fontSize: 30),
                          hintText: "insert band letters",
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: (BorderSide(color: Colors.white))),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Flexible(
                      flex: 3,
                      child: TextFormField(
                        controller: band_id_numbers,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.blue,
                          labelText: "numbers",
                          labelStyle:
                              TextStyle(color: Colors.white, fontSize: 30),
                          hintText: "insert band numbers",
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: (BorderSide(color: Colors.white))),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 35),
                Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        style: TextStyle(color: Colors.black),
                        controller: nestID,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.greenAccent,
                          labelText: "nestID",
                          labelStyle:
                              TextStyle(color: Colors.teal[800], fontSize: 30),
                          hintText: "insert nestID",
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: (BorderSide(color: Colors.white))),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                    ),
                    Flexible(
                      child: TextFormField(
                        style: TextStyle(color: Colors.black),
                        controller: eggNr,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.greenAccent,
                          labelText: "egg nr",
                          labelStyle:
                              TextStyle(color: Colors.teal[800], fontSize: 30),
                          hintText: "insert egg number",
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: (BorderSide(color: Colors.white))),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: age,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintStyle: TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.greenAccent,
                    labelText: "age",
                    labelStyle:
                        TextStyle(color: Colors.teal[800], fontSize: 30),
                    hintText: "insert age (code)",
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: (BorderSide(color: Colors.white))),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                IconButton(
                  color: Colors.white,
                  splashRadius: 550,
                  splashColor: Colors.redAccent[700],
                  iconSize: 60,
                  onPressed: () async {
                    var date = DateTime.now();
                    bool isok = true;
                    var _species = species.text;
                    String bandletter = band_id_letters.text.toUpperCase();
                    int bandnr = int.parse(band_id_numbers.text);
                    var band = bandletter + bandnr.toString();
                    var _age = age.text;
                    String _nest = nestID.text;
                    String egg = eggNr.text;
                    if(bandletter.length < 1){
                      showDialog(context: context, builder: (_) =>
                          AlertDialog(
                            title: Text("$band has no letters!",
                                style: TextStyle(color: Colors.deepPurpleAccent)
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          ));
                      return;
                    }

                    if (_nest == "" && egg != "") {
                      return;
                    }
                    if (_nest != "" && egg != "") {
                      await nest
                          .doc(_nest)
                          .collection("egg")
                          .doc("$_nest egg $egg")
                          .get()
                          .then((value) {
                        if (value.data()!.containsKey("ring")) {

                          isok = false;
                        }
                      });
                    }
                    if (isok && username != null) {
                      Map<String, dynamic> list = {
                        "ringed_date": date,
                        "species": _species,
                        "band": band,
                        "age": _age,
                        "responsible": username
                      };

                      egg == "" ? null : list.addAll({"egg": egg});
                      _nest == "" ? null : list.addAll({"nest": _nest});
                      birds.doc(band).get().then((value) {
                        if (!value.exists) {
                          birds.doc(band).set(list);
                          recent_band
                              .doc("UA")
                              .set({bandletter: bandnr})
                              .whenComplete(() => birds
                                  .doc(band)
                                  .collection("changelog")
                                  .doc(date.toString())
                                  .set(list))
                              .whenComplete(() => nest
                                  .doc(_nest)
                                  .collection("egg")
                                  .doc("$_nest egg $egg")
                                  .update({'ring': band, 'status':'hatched'}));
                          Navigator.pop(context);
                        } else{
                          showDialog(context: context, builder: (_) =>
                              AlertDialog(
                                title: Text("$band already used!",
                                    style: TextStyle(color: Colors.deepPurpleAccent)
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("OK"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              ));
                        }
                      });
                    }
                  },
                  icon: Icon(
                    Icons.save_outlined,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
