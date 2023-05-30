import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/buildForm.dart';
import 'package:kakrarahu/species.dart';

class NestManage extends StatefulWidget {
  const NestManage({Key? key}) : super(key: key);

  @override
  State<NestManage> createState() => _NestManageState();
}

class _NestManageState extends State<NestManage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FocusNode _focusNode = FocusNode();
  final species = new TextEditingController();
  final nestID = new TextEditingController();
  final remark = new TextEditingController();

  static String _displayStringForOption(SpeciesList option) => option.english;

/*  final StreamController<bool> _checkBoxController = StreamController();
  Stream<bool> get _checkBoxStream => _checkBoxController.stream;*/
  var new_egg_nr;
  var save;
  var mune;
  var username;
  var exists;
  Map<String, dynamic> database = {};
  bool signed = false;
  var map = <String, dynamic>{};

  void addItem(value, String key) {
    if (value != null) {
      map.addEntries({key: value}.entries);
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

  final pesa = FirebaseFirestore.instance.collection('2023');

  Widget build(BuildContext context) {
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
    final data = ModalRoute.of(context)?.settings.arguments as Map;
    nestID.text = data["sihtkoht"];

    pesa.doc(data["sihtkoht"]).get().then((value) {
      database = value.data() as Map<String, dynamic>;
      species.text = database["species"];
      remark.text = database["remark"];
    });
    try {
      species.text = data["species"];
    } catch (e) {}
    try {
      remark.text = data["remark"];
    } catch (e) {}
    final Stream<QuerySnapshot> _eggStream = FirebaseFirestore.instance
        .collection('2023')
        .doc(data["sihtkoht"])
        .collection("egg")
        .snapshots();

    pesa
        .doc(data["sihtkoht"])
        .collection("egg")
        .get()
        .then((value) => mune = value.docs.length);
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                new Text(data["sihtkoht"],
                    style:
                        TextStyle(fontSize: 30, fontStyle: FontStyle.italic)),
                FutureBuilder(
                  future: pesa.doc(data["sihtkoht"]).get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                          snapshot) {
                    if (snapshot.hasError) {
                      return Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading");
                    }
                    return Column(
                      children: [
                        Text(snapshot.data!.data()!.containsKey("experiment")
                            ? snapshot.data?.get("experiment")
                            : ""),
                        Text(snapshot.data?.get("last_modified").toDate().day ==
                                DateTime.now().day
                            ? "CHECKED"
                            : "")
                      ],
                    );
                  },
                )
                //Icon(Icons.check_circle,color: Colors.green,size: 40,)
              ]),
              SizedBox(height: 15),
              RawAutocomplete<SpeciesList>(
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
              buildForm(context, "remark", null, remark),
              StreamBuilder<QuerySnapshot>(
                stream: _eggStream,
                builder: (context, snapshot) {
                  return Flexible(
                    child: Column(
                      children: [
                        Flexible(
                          child: ListView.builder(
                              itemCount: snapshot.data?.docs.length ?? 0,
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                if (snapshot.hasError) {
                                  return Text('Something went wrong');
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text("Loading");
                                }
                                var id =
                                    snapshot.data?.docs[index].id.split(" ")[2];
                                var status =
                                    snapshot.data?.docs[index].get("status");
                                var ringed = snapshot.data?.docs[index]
                                        .data()
                                        .toString()
                                        .contains("ring") ??
                                    false;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: status == "intact" ||
                                                  status == "unknown"
                                              ? Colors.green
                                              : (status == "broken" ||
                                                      status == "missing" ||
                                                      status == "predated" ||
                                                      status == "drowned"
                                                  ? Colors.red
                                                  : Colors.orange[800])),
                                      child: (Text("Egg " +
                                          (id).toString() +
                                          " $status" +
                                          (ringed
                                              ? "/" +
                                                  snapshot.data?.docs[index]
                                                      .get("ring")
                                              : ""))),
                                      onPressed: () {
                                        Navigator.pushNamed(context, "/eggs",
                                            arguments: {
                                              "sihtkoht": data["sihtkoht"],
                                              "egg": data["sihtkoht"] +
                                                  " egg " +
                                                  (id).toString()
                                            });
                                      },
                                      onLongPress: () {
                                        Navigator.pushNamed(
                                            context, "/individual",
                                            arguments: {
                                              "pesa":
                                                  (data["sihtkoht"]).toString(),
                                              "muna_nr": (id).toString(),
                                              "species": database["species"]
                                                  .toString(),
                                              "age": "1"
                                            });
                                      },
                                    ),
                                    SizedBox(height: 5),
                                  ],
                                );
                              }),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection("Birds")
                                    .where("nest", isEqualTo: data["sihtkoht"])
                                    .where("ringed_date", isGreaterThan: DateTime(2023))
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  var amount = snapshot.data?.size;
                                  return Text(
                                    "Ringed ($amount)",
                                    style: TextStyle(fontSize: 10),
                                  );
                                }),
                            new ElevatedButton.icon(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.grey)),
                                onPressed: () {
                                  if (snapshot.data!.docs.length != null &&
                                      snapshot.hasError == false) {
                                    new_egg_nr =
                                        ((snapshot.data!.docs.length) + 1);
                                    pesa
                                        .doc(data["sihtkoht"])
                                        .collection("egg")
                                        .doc(data["sihtkoht"] +
                                            " egg " +
                                            new_egg_nr.toString())
                                        .set({
                                      "discover_date": DateTime.now().toLocal(),
                                      "responsible": username,
                                      "status": "intact",
                                    }).whenComplete(() => pesa
                                                .doc(data["sihtkoht"])
                                                .collection("egg")
                                                .doc(data["sihtkoht"] +
                                                    " egg " +
                                                    new_egg_nr.toString())
                                                .collection("changelog")
                                                .doc(DateTime.now().toString())
                                                .set({
                                              "discover_date":
                                                  DateTime.now().toLocal(),
                                              "responsible": username,
                                              "status": "intact",
                                            }));
                                    /*Navigator.pushNamed(context, "/eggs",
                                          arguments: {
                                            "sihtkoht": data["sihtkoht"],
                                            "egg": data["sihtkoht"] +
                                                " egg " +
                                                new_egg_nr.toString()
                                          });*/
                                  }
                                },
                                icon: Icon(
                                  Icons.egg,
                                  size: 45,
                                ),
                                onLongPress: () {
                                  Navigator.pushNamed(context, "/individual",
                                      arguments: {
                                        "pesa": (data["sihtkoht"]).toString(),
                                        "species":
                                            database["species"].toString(),
                                        "age": "1"
                                      });
                                },
                                label: Column(
                                  children: [
                                    Text("add egg"),
                                    Text(
                                      "(long press for chick)",
                                      style: TextStyle(fontSize: 10),
                                    )
                                  ],
                                )),
                            SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                new ElevatedButton.icon(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.red[900])),
                                    onPressed: () {
                                      showDialog<String>(
                                        barrierColor: Colors.black,
                                        context: context,
                                        builder: (BuildContext context) =>
                                            AlertDialog(
                                          contentTextStyle:
                                              TextStyle(color: Colors.black),
                                          titleTextStyle:
                                              TextStyle(color: Colors.red),
                                          title: const Text("Removing nest"),
                                          content: const Text(
                                              'Are you sure you want to delete this nest?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  context, 'Cancel'),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                var time = DateTime.now();
                                                var kust =
                                                    pesa.doc(data["sihtkoht"]);
                                                kust
                                                    .collection("changelog")
                                                    .get()
                                                    .then((value) => value.docs
                                                            .forEach((element) {
                                                          element.reference
                                                              .update({
                                                            "deleted": time
                                                          });
                                                        }));
                                                kust.delete();
                                                kust
                                                    .collection("egg")
                                                    .get()
                                                    .then((value) => value.docs
                                                            .forEach((element) {
                                                          element.reference
                                                              .collection(
                                                                  "changelog")
                                                              .get()
                                                              .then((value2) =>
                                                                  value2.docs
                                                                      .forEach(
                                                                          (element2) {
                                                                    element2
                                                                        .reference
                                                                        .update({
                                                                      "deleted":
                                                                          time
                                                                    });
                                                                  }));
                                                          element.reference
                                                              .delete();
                                                        }));

                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      size: 45,
                                    ),
                                    label: Text("delete")),
                                StreamBuilder<Object>(
                                    stream: null,
                                    builder: (context, snapshot) {
                                      return new ElevatedButton.icon(
                                          onPressed: () async => {
                                                save = data["sihtkoht"],
                                                //addItem(coords, "coordinates"),
                                                //addItem(accuracy, "accuracy"),
                                                addItem(
                                                    username, "responsible"),
                                                addItem(
                                                    species.text, "species"),
                                                addItem(remark.text, "remark"),
                                                exists =
                                                    await pesa.doc(save).get(),
                                                if (exists.exists == true)
                                                  {
                                                    print("ei eksisteeri"),
                                                    pesa
                                                        .doc(save)
                                                        .update(map)
                                                        .then((value) => pesa
                                                                .doc(save)
                                                                .update({
                                                              "last_modified":
                                                                  DateTime.now()
                                                            })),
                                                    map.addAll({"a": "B"}),
                                                    pesa
                                                        .doc(save)
                                                        .collection("changelog")
                                                        .doc(DateTime.now()
                                                            .toString())
                                                        .set(map)
                                                        .then((value) =>
                                                            print("Success"))
                                                        .catchError((error) =>
                                                            print(
                                                                "Failed: $error")),
                                                    Navigator.pop(context),
                                                  }
                                                else
                                                  {
                                                    showDialog<String>(
                                                      barrierColor:
                                                          Colors.black,
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          AlertDialog(
                                                        contentTextStyle:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black),
                                                        titleTextStyle:
                                                            TextStyle(
                                                                color:
                                                                    Colors.red),
                                                        title: const Text(
                                                            "Nest does not yet exist"),
                                                        content: const Text(
                                                            'Do you want to declare a new nest?'),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    'Cancel'),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context,
                                                                  'OK');
                                                              Navigator
                                                                  .popAndPushNamed(
                                                                      context,
                                                                      "/pesa",
                                                                      arguments: {
                                                                    "sihtkoht":
                                                                        data[
                                                                            "sihtkoht"]
                                                                  });
                                                            },
                                                            child: const Text(
                                                                'OK'),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  }, //ALERTDIALOG
                                              },
                                          icon: Icon(
                                            Icons.save,
                                            color: Colors.black87,
                                            size: 45,
                                          ),
                                          label: Text("save and check"));
                                    }), //save button
                                /*StreamBuilder(
                      stream: _checkBoxStream,
                      initialData: false,
                      builder: (BuildContext context, AsyncSnapshot<bool> snapshot ){
                        return Theme(
                          data: ThemeData(
                            primarySwatch: Colors.blue,
                            unselectedWidgetColor: Colors.red, // Your color
                          ),
                          child: Checkbox(
                              value: snapshot.data,
                              onChanged: (changedValue){
                                _checkBoxController.sink.add(changedValue!);
                              }
                          ),
                        );
                      }),*/
                              ],
                            ), //asukoht ja save nupp
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
