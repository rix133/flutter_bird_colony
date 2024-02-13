import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:kakrarahu/design/speciesInput.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/measure.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'package:kakrarahu/models/bird.dart';

class NestManage extends StatefulWidget {
  const NestManage({Key? key}) : super(key: key);

  @override
  State<NestManage> createState() => _NestManageState();
}

class _NestManageState extends State<NestManage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FocusNode _focusNode = FocusNode();
  final species = new TextEditingController();

  var new_egg_nr;
  var save;
  var exists;
  List<Bird> parents = [];
  Nest? nest;
  Map<String, dynamic> database = {};
  late CollectionReference nests;
  Stream<QuerySnapshot> _eggStream = Stream.empty();
  late SharedPreferencesService sps;


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
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      var data = ModalRoute.of(context)?.settings.arguments as Map;

      nests.doc(data["sihtkoht"]).get().then((value) {
        if(value.exists){
          setState(() {
            nest = Nest.fromQuerySnapshot(value);
            species.text = nest!.species ?? "";
          });
        }

      });
    });
  }

  Nest getNest(BuildContext context) {
    if(nest != null) {
      nest!.species = species.text;
      nest!.responsible = sps.userName;
      return nest!;
    }
    throw Exception("Nest is not initialized");
  }


  StreamBuilder _getEggsStream(Stream<QuerySnapshot> _eggStream){
    return(StreamBuilder<QuerySnapshot>(
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
                                  context, "/editChick",
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
                          if(new_egg_nr == 1){nest!.first_egg = DateTime.now();}
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
                        }
                      },
                      icon: Icon(
                        Icons.egg,
                        size: 45,
                      ),
                      onLongPress: () {
                        Navigator.pushNamed(context, "/editChick",
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
                ],
              ),
            ],
          ),
        );
      },
    ));
  }

  void gotoParent() {
    Navigator.pushNamed(context, "/editParent", arguments: {
      "nest": nest,
    });
  }

  Widget _getParentsRow(List<Bird>? _parents, BuildContext context) {
    return  SingleChildScrollView(
        scrollDirection: Axis.horizontal,
      child:Container(
          height: 50.0, // Adjust this value as needed
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  ...?_parents?.map((Bird b) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/editParent", arguments: {
                        "bird": b,
                        "nest": nest,
                      });
                    },
                    child: Text(b.name),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white60),
                    ),
                  );
                }).toList(),
              (_parents?.length == 0 || _parents == null) ? ElevatedButton.icon(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.grey)),
                  onPressed: gotoParent,
                  icon: Icon(
                    Icons.add,
                  ),
                  label: Text("add parent")) : IconButton(icon:Icon(Icons.add),onPressed: gotoParent, style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white60),
              ),),
            ],
          )),
        );
  }

 void addMeasure(Measure m) {
    setState(() {
      nest!.measures.add(m);
      nest!.measures.sort();
    });
  }

  Row getTitleRow(){
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: nest!.name,
              style: TextStyle(fontSize: 30, fontStyle: FontStyle.italic),
            ),
            WidgetSpan(
              child: Transform.translate(
                offset: const Offset(0.0, 5.0),
                child: Text(
                  nest!.checkedStr(),
                  style: TextStyle(
                      fontSize: 12.0,
                      color: nest!.chekedAgo().inDays == 0 ? Colors.green : Colors.yellow.shade700
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    ]);
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


    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              getTitleRow(),
              listExperiments(nest!), //list of experiments
              SizedBox(height: 15),
              buildRawAutocomplete(species, _focusNode),
              SizedBox(height: 15),
              ...nest!.measures.map((Measure m) => m.getMeasureFormWithAddButton(addMeasure)).toList(),
              SizedBox(height: 15),
              _getParentsRow(nest!.parents, context),
              _getEggsStream(_eggStream),
              modifingButtons(context, getNest, "modify", null, null, null),
            ],
          ),
        ),
      ),
    );
  }
}
