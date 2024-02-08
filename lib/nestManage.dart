import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/buildForm.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/species.dart';
import 'package:provider/provider.dart';

import 'models/bird.dart';

class NestManage extends StatefulWidget {
  const NestManage({Key? key}) : super(key: key);

  @override
  State<NestManage> createState() => _NestManageState();
}

class _NestManageState extends State<NestManage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FocusNode _focusNode = FocusNode();
  final species = new TextEditingController();
  final remark = new TextEditingController();

  static String _displayStringForOption(SpeciesList option) => option.english;

/*  final StreamController<bool> _checkBoxController = StreamController();
  Stream<bool> get _checkBoxStream => _checkBoxController.stream;*/
  var new_egg_nr;
  var save;
  int _eggCount = 0;
  var exists;
  List<Bird> parents = [];
  Nest? nest;
  Map<String, dynamic> database = {};
  late CollectionReference nests;
  late Stream<QuerySnapshot> _eggStream;
  late Stream<QuerySnapshot> _parentStream;


  String get _year => DateTime.now().year.toString();
  var map = <String, dynamic>{};

  void addItem(value, String key) {
    if (value != null) {
      map.addEntries({key: value}.entries);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    nests = FirebaseFirestore.instance.collection(_year);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var data = ModalRoute.of(context)?.settings.arguments as Map;

      nests.doc(data["sihtkoht"]).get().then((value) {
        setState(() {
          nest = Nest.fromQuerySnapshot(value);
          species.text = nest!.species ?? "";
          remark.text = nest!.remark ?? "";
        });
      });
    });
  }

  Row modifingButtons(BuildContext context, CollectionReference nests,
      Nest? nest, SharedPreferencesService sps) {
    return (Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        new ElevatedButton.icon(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red[900])),
            onPressed: () {
              showDialog<String>(
                barrierColor: Colors.black,
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  contentTextStyle: TextStyle(color: Colors.black),
                  titleTextStyle: TextStyle(color: Colors.red),
                  title: const Text("Removing nest"),
                  content:
                      const Text('Are you sure you want to delete this nest?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancel'),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        var time = DateTime.now();
                        var kust = nests.doc(nest!.name);
                        kust
                            .collection("changelog")
                            .get()
                            .then((value) => value.docs.forEach((element) {
                                  element.reference.update({"deleted": time});
                                }));
                        kust.delete();
                        kust
                            .collection("egg")
                            .get()
                            .then((value) => value.docs.forEach((element) {
                                  element.reference
                                      .collection("changelog")
                                      .get()
                                      .then((value2) =>
                                          value2.docs.forEach((element2) {
                                            element2.reference
                                                .update({"deleted": time});
                                          }));
                                  element.reference.delete();
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
                        save = nest!.name,
                        //addItem(coords, "coordinates"),
                        //addItem(accuracy, "accuracy"),
                        addItem(sps.userName, "responsible"),
                        addItem(species.text, "species"),
                        addItem(remark.text, "remark"),
                        exists = await nests.doc(save).get(),
                        if (exists.exists == true)
                          {
                            print("ei eksisteeri"),
                            nests.doc(save).update(map).then((value) => nests
                                .doc(save)
                                .update({"last_modified": DateTime.now()})),
                            map.addAll({"a": "B"}),
                            nests
                                .doc(save)
                                .collection("changelog")
                                .doc(DateTime.now().toString())
                                .set(map)
                                .then((value) => print("Success"))
                                .catchError((error) => print("Failed: $error")),
                            Navigator.pop(context),
                          }
                        else
                          {
                            showDialog<String>(
                              barrierColor: Colors.black,
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                contentTextStyle:
                                    TextStyle(color: Colors.black),
                                titleTextStyle: TextStyle(color: Colors.red),
                                title: const Text("Nest does not yet exist"),
                                content: const Text(
                                    'Do you want to declare a new nest?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Cancel'),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, 'OK');
                                      Navigator.popAndPushNamed(
                                          context, "/pesa",
                                          arguments: {"sihtkoht": nest!.name});
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            )
                          },
                        //ALERTDIALOG
                      },
                  icon: Icon(
                    Icons.save,
                    color: Colors.black87,
                    size: 45,
                  ),
                  label: Text("save and check"));
            }), //save button
      ],
    ));
  }

  StreamBuilder _getParentsRow(Stream<QuerySnapshot> _parentStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: _parentStream,
      builder: (context, snapshot) {
        return Container(
          height: 50.0, // Adjust this value as needed
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child:ListView.builder(
                itemCount: snapshot.data?.docs.length ?? 0,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Text("Loading");
                  } else {
                    Bird b =
                    Bird.fromQuerySnapshot(snapshot.data!.docs[index]);
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: EdgeInsets.all(5)),
                      child: (Text(b.name)),
                      onPressed: () {},
                    );
                  }
                },
              )),
              ElevatedButton.icon(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.grey)),
                  onPressed: () {
                    Navigator.pushNamed(context, "/editparent", arguments: {
                      "nest": nest,
                    });
                  },
                  icon: Icon(
                    Icons.add,
                    size: 45,
                  ),
                  label: Text("parent")),
            ],
          ),
        );
      },
    );
  }



  // Function to build RawAutocomplete
  Widget buildRawAutocomplete(TextEditingController species) {
    return RawAutocomplete<SpeciesList>(
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
            labelStyle: TextStyle(color: Colors.yellow),
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
    );
  }

  Widget build(BuildContext context) {
    if (nest == null) {
      // Return a CircularProgressIndicator while nest is loading
      return Scaffold(
        body: Center(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[CircularProgressIndicator()],
            ),
          ),
        ),
      );
    }
    _eggStream = FirebaseFirestore.instance
        .collection(_year)
        .doc(nest!.id)
        .collection("egg")
        .snapshots();

    _parentStream = FirebaseFirestore.instance
        .collection(_year)
        .doc(nest!.id)
        .collection("parents")
        .snapshots();


    final sps = Provider.of<SharedPreferencesService>(context, listen: false);
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                new Text(nest!.name,
                    style:
                        TextStyle(fontSize: 30, fontStyle: FontStyle.italic)),
                FutureBuilder(
                  future: nests.doc(nest!.id).get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot<Object?>> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading");
                    }
                    Map<String, dynamic> data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      children: [
                        Text(data.containsKey("experiment")
                            ? data["experiment"].toString()
                            : ""),
                        Text(
                            (data["last_modified"] as Timestamp).toDate().day ==
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
              buildRawAutocomplete(species),
              SizedBox(height: 15),
              buildForm(context, "remark", null, remark),
              _getParentsRow(_parentStream),
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
                                              "sihtkoht": nest!.name,
                                              "egg": nest!.name +
                                                  " egg " +
                                                  (id).toString()
                                            });
                                      },
                                      onLongPress: () {
                                        Navigator.pushNamed(
                                            context, "/editchick",
                                            arguments: {
                                              "pesa": nest!.name,
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
                                    .where("nest", isEqualTo: nest!.name)
                                    .where("ringed_date",
                                        isGreaterThan:
                                            DateTime(DateTime.now().year))
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
                                    nests
                                        .doc(nest!.name)
                                        .collection("egg")
                                        .doc(nest!.name +
                                            " egg " +
                                            new_egg_nr.toString())
                                        .set({
                                      "discover_date": DateTime.now().toLocal(),
                                      "responsible": sps.userName,
                                      "status": "intact",
                                    }).whenComplete(() => nests
                                                .doc(nest!.name)
                                                .collection("egg")
                                                .doc(nest!.name +
                                                    " egg " +
                                                    new_egg_nr.toString())
                                                .collection("changelog")
                                                .doc(DateTime.now().toString())
                                                .set({
                                              "discover_date":
                                                  DateTime.now().toLocal(),
                                              "responsible": sps.userName,
                                              "status": "intact",
                                            }));
                                    /*Navigator.pushNamed(context, "/eggs",
                                          arguments: {
                                            "sihtkoht": nest.name,
                                            "egg": nest.name +
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
                                  Navigator.pushNamed(context, "/editchick",
                                      arguments: {
                                        "pesa": (nest!.name).toString(),
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
                            modifingButtons(context, nests, nest, sps),
                            //asukoht ja save nupp
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
