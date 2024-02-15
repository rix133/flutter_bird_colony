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

import 'models/egg.dart';

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
            nest = Nest.fromDocSnapshot(value);
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
    Egg egg;
    return(StreamBuilder<QuerySnapshot>(
      stream: _eggStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if(snapshot.hasData){

          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...snapshot.data!.docs.map((doc) {
                  egg = Egg.fromDocSnapshot(doc);
                  if(nest!.first_egg == null){
                      nest!.first_egg = egg.discover_date;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      egg.getButton(context, nest),
                      SizedBox(height: 5),
                    ],
                  );
                }).toList(),
                ..._getAddEggButton(context, snapshot),

              ],
            ),
          );
        }

        return SizedBox.shrink(); // Return an empty widget if there's no data
      },
    ));
  }

  List<Widget> _getAddEggButton(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
    if (!snapshot.hasData) {
      return [Text('No data')];
    }
    int amount = snapshot.data!.docs.map((e) => Egg.fromDocSnapshot(e)).where((e) => e.ring != null).length;
    return [
      Text(
        "Ringed ($amount)",
        style: TextStyle(fontSize: 10),
      ),
      ElevatedButton.icon(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey)
          ),
          onPressed: () {
            if (snapshot.data!.docs.isNotEmpty) {
              Egg egg = Egg(
                  discover_date: DateTime.now(),
                  responsible: sps.userName,
                  status: "intact",
                  ring: null
              );
              new_egg_nr = snapshot.data!.docs.length + 1;
              if(new_egg_nr == 1){nest!.first_egg = DateTime.now();}
              String eggID = nest!.name + " egg " + new_egg_nr.toString();
              nests
                  .doc(nest!.id).collection("egg").doc(eggID)
                  .set(egg.toJson()).whenComplete(() => nests
                  .doc(eggID)
                  .collection("changelog")
                  .doc(DateTime.now().toString())
                  .set(egg.toJson()));
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
                  "species": nest!.species,
                  "age": "0"
                }
            );
          },
          label: Column(
            children: [
              Text("add egg"),
              Text(
                "(long press for chick)",
                style: TextStyle(fontSize: 10),
              )
            ],
          )
      ),
      SizedBox(height: 15),
    ];
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
                      backgroundColor: MaterialStateProperty.all(_getParentButtonColor())),
                  onPressed: gotoParent,
                  icon: Icon(
                    Icons.add,
                  ),
                  label: Text("add parent")) : IconButton(icon:Icon(Icons.add),onPressed: gotoParent, style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white60),
              ),),
              _daysSinceFirstEgg() > 0 ? Align(child:Text("${_daysSinceFirstEgg()} days", style: TextStyle(fontSize: 18)),alignment: Alignment.centerLeft) : Container(),

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

  Color _getParentButtonColor(){
    if(_daysSinceFirstEgg() > 10){
      return Colors.lightGreenAccent;
    }
    return Colors.grey;
  }

  int _daysSinceFirstEgg(){
    return DateTime.now().difference(nest!.first_egg ?? DateTime.now()).inDays;
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
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
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
            SizedBox(height: 30),
            modifingButtons(context, getNest, "modify", null, null, null),
            ],
          ),
        ))),
    );
  }
}
