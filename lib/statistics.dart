
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search.dart' as globals;

class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  var today = DateTime.now().toIso8601String().split("T")[0];

  CollectionReference pesa = FirebaseFirestore.instance.collection('2023');
  CollectionReference lind = FirebaseFirestore.instance.collection('Birds');

  String username = "";

  final search = TextEditingController();

  List<DropdownMenuItem<String>> timespans = <DropdownMenuItem<String>>[
    DropdownMenuItem(child: Text("All", style: TextStyle(color: Colors.deepPurpleAccent)), value: "All" ),
    DropdownMenuItem(child: Text("Today", style: TextStyle(color: Colors.deepPurpleAccent)), value: "Today")
  ];
  String dropdownValue = "All";

  List<DropdownMenuItem<String>> people = <DropdownMenuItem<String>>[
    DropdownMenuItem(child: Text("Everybody", style: TextStyle(color: Colors.deepPurpleAccent)), value: "Everybody" ),
    DropdownMenuItem(child: Text("Me", style: TextStyle(color: Colors.deepPurpleAccent)), value: "Me")
  ];
  String dropdownValuePeople = "Everybody";


  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    search.text = globals.search;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
      } else {
        username = user.displayName.toString();
      }
    });

    Query birds = lind.where("ringed_date", isGreaterThanOrEqualTo: DateTime(2023));
    Stream<QuerySnapshot> _nestsStream = pesa.snapshots();
    Stream<QuerySnapshot> _birdsStream = birds.snapshots();

    return Scaffold(
        appBar: AppBar(
          title: Text("Some statistics"),
          backgroundColor: Colors.amberAccent,
        ),
        body: Column(
          children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Select timeframe:'),
            Container(width: 8),
            DropdownButton<String>(
              value: dropdownValue,
              items: timespans,
              onChanged: (String? newValue) {
                print(newValue);
                setState(() {
                  dropdownValue = newValue!;
                });
              },
            )]),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Select user:'),
                  Container(width: 8),
                  DropdownButton<String>(
                    value: dropdownValuePeople,
                    items: people,
                    onChanged: (String? newValue) {
                      print(newValue);
                      setState(() {
                        dropdownValuePeople = newValue!;
                      });
                    },
                  )]),
            Expanded(
                child: StreamBuilder(
                    stream: _nestsStream,
                    builder:
                        (context, AsyncSnapshot<QuerySnapshot> snapshot_nests) {
                      if (snapshot_nests.hasData) {
                        List<Nest> nests = snapshot_nests.data!.docs
                            .map((e) => Nest.fromQuerySnapshot(e))
                            .toList();
                        nests = nests.where((Nest n) => n.timeSpan(dropdownValue)).toList();
                        nests = nests.where((Nest n) => n.people(dropdownValuePeople, username)).toList();

                        return ListView(
                          children: [
                            ListTile(
                                title: Text("Total nests"),
                                trailing: Text(nests.length.toString())),
                            ListTile(
                                title: Text("Common gull nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                        nest.species == "Common Gull")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Arctic tern nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "Arctic Tern")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Common tern nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "Common Tern")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Mute Swan nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "Mute Swan")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Great Black-backed Gull nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "Great Black-backed Gull")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Eurasian Oystercatcher nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "Eurasian Oystercatcher")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("European Herring Gull nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "European Herring Gull")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Black-Headed Gull nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "Black-Headed Gull")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Mallard nests"),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "Mallard")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("No species nests"),
                                subtitle: Text(nests.where((Nest nest) =>nest.species == "").toList().map((Nest n)=> n.id ?? "").toList().join(", ")),
                                trailing: Text(nests
                                    .where((Nest nest) =>
                                nest.species == "")
                                    .toList()
                                    .length
                                    .toString()))
                          ],
                        );
                      } else {
                        return Container(
                            padding: EdgeInsets.all(40.0),
                            child: Text("loading nests..."));
                      }
                    })),
            SizedBox(height: 20),
            Row(children: [Text("Banding data:")]),
            SizedBox(height: 20),
            Expanded(
                child: StreamBuilder(
                    stream: _birdsStream,
                    builder:
                        (context, AsyncSnapshot<QuerySnapshot> snapshot_birds) {
                      if (snapshot_birds.hasData) {
                        List<Bird> birds = snapshot_birds.data!.docs
                            .map((e) => Bird.fromQuerySnapshot(e))
                            .toList();
                        birds = birds.where((Bird b) => b.timeSpan(dropdownValue)).toList();
                        birds = birds.where((Bird b) => b.people(dropdownValuePeople, username)).toList();
                        return ListView(
                          children: [
                            ListTile(
                                title: Text("Total ringed"),
                                trailing: Text(birds.length.toString())),
                            ListTile(
                                title: Text("Common gulls ringed"),
                                trailing: Text(birds
                                    .where((Bird bird) =>
                                bird.species == "Common Gull")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Arctic terns ringed"),
                                trailing: Text(birds
                                    .where((Bird bird) =>
                                bird.species == "Arctic Tern")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Common tern nests"),
                                trailing: Text(birds
                                    .where((Bird bird) =>
                                bird.species == "Common Tern")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Great Black-backed Gulls ringed"),
                                trailing: Text(birds
                                    .where((Bird bird) =>
                                bird.species == "Great Black-backed Gull")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("Eurasian Oystercatcher ringed"),
                                trailing: Text(birds
                                    .where((Bird bird) =>
                                bird.species == "Eurasian Oystercatcher")
                                    .toList()
                                    .length
                                    .toString())),
                            ListTile(
                                title: Text("European Herring Gull ringed"),
                                trailing: Text(birds
                                    .where((Bird bird) =>
                                bird.species == "European Herring Gull")
                                    .toList()
                                    .length
                                    .toString())),
                          ],
                        );
                      } else {
                        return Container(
                            padding: EdgeInsets.all(40.0),
                            child: Text("loading birds..."));
                      }
                    }))
          ],
        ));
  }

  void onChangedTimespan(value) {
    print(value);
  }
}
