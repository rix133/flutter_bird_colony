import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/species.dart';
import 'package:provider/provider.dart';

class EditChick extends StatefulWidget {
  const EditChick({Key? key}) : super(key: key);

  @override
  State<EditChick> createState() => _EditChickState();
}

class _EditChickState extends State<EditChick> {
  TextEditingController band_id_letters = TextEditingController();
  TextEditingController band_id_numbers = TextEditingController();
  TextEditingController nestID = TextEditingController();
  TextEditingController eggNr = TextEditingController();
  TextEditingController species = TextEditingController();
  TextEditingController age = TextEditingController();
  FocusNode _focusNode = FocusNode();

  CollectionReference nests = FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  CollectionReference birds = FirebaseFirestore.instance.collection("Birds");

  String _recentBand = "";
  late SharedPreferencesService sharedPreferencesService;

  static String _displayStringForOption(SpeciesList option) => option.english;
  var username;
  var uid;

  @override
  void initState() {
    super.initState();
    sharedPreferencesService = Provider.of<SharedPreferencesService>(context, listen: false);
    _recentBand = sharedPreferencesService.recentBand;
  }

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


    if (species.text == "Common Gull") {
      band_id_letters.text = "UA";
      if(_recentBand.length > 2){
        band_id_numbers.text = _recentBand.substring(2, _recentBand.length);
      }

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
                      if (selectedString.english == "Common Gull") {
                        band_id_letters.text = "UA";
                        band_id_numbers.text = _recentBand.substring(2, _recentBand.length);
                      }
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
                      await nests
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
                      //make a bird
                      Bird bird = Bird(
                          ringed_date: date,
                          band: band,
                          species: _species,
                          age: _age,
                          responsible: username,
                          egg: egg,
                          nest: _nest,
                          measures: []);
                      UpdateResult saveOK =  await bird.save(otherItems: nests, allowOverwrite: false, type: "chick");
                      if(saveOK.success){
                        sharedPreferencesService.recentBand = band;
                        Navigator.pop(context);
                      } else{
                        showDialog(context: context, builder: (_) =>
                            AlertDialog(
                              title: Text("$band already used! or ${saveOK.message}",
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
