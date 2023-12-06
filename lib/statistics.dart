
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search.dart' as globals;
import 'services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';
import 'species.dart';

class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  var today = DateTime.now().toIso8601String().split("T")[0];

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

    final sharedPreferencesService = Provider.of<SharedPreferencesService>(context);
    int selectedYear = sharedPreferencesService.selectedYear;
    String yearString = sharedPreferencesService.selectedYearString;
    CollectionReference pesa = FirebaseFirestore.instance.collection(yearString);

    DateTime startDate = DateTime(selectedYear);
    DateTime endDate = DateTime(selectedYear + 1);

    Query birds = lind
        .where("ringed_date", isGreaterThanOrEqualTo: startDate)
        .where("ringed_date", isLessThan: endDate);

    Stream<QuerySnapshot> _nestsStream = pesa.snapshots();
    Stream<QuerySnapshot> _birdsStream = birds.snapshots();

    return Scaffold(
        appBar: AppBar(
          title: Text("Some statistics", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.amberAccent,
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Select timeframe:'),
                  Container(width: 8),
                  DropdownButton<String>(
                    value: dropdownValue,
                    items: timespans,
                    onChanged: (String? newValue) {
                      //print(newValue);
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                  )
                ],
              ),
            ),
            Container(
            color: Theme.of(context).scaffoldBackgroundColor,  // Replace with your desired color
              child:
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
                  )])),
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
                            getNestListTile("Common Gull", nests, experimental: true),
                            ...Species.english.map((SpeciesList sp) => getNestListTile(sp.english, nests)).toList(),
                            getNestListTile("", nests),
                          ],
                        );
                      } else {
                        return Container(
                            padding: EdgeInsets.all(40.0),
                            child: Text("loading nests..."));
                      }
                    })),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            color: Theme.of(context).scaffoldBackgroundColor,  // Replace with your desired color
                child: Row(children: [Text("Banding data:")]),
            ),
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
                            ...Species.english.map((SpeciesList sp) => getBirdsListTile(sp.english, birds)).toList(),
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

  Widget  getNestListTile(String species, List<Nest> nests,
      {bool experimental = false}){
    List<Nest> selectedNests = nests
        .where((Nest nest) =>
    nest.species == species)
        .toList();
    if(selectedNests.length == 0){return SizedBox.shrink();}
    if(experimental){
      selectedNests = selectedNests.where((Nest n) => n.id!.startsWith("e")).toList();
      species = "Experiment";
    }
    ListTile list_tile = ListTile(
        title: Text(species == "" ? "No species nests" : "$species nests"),
        //leading: Text(selectedNests.map((Nest e) => e.eggCount()).reduce((a, b) => a + b).toString()),
        trailing: Text(selectedNests.length.toString()),
        onTap: () => showNestsonMap(selectedNests));

    return list_tile;
  }
  Widget  getBirdsListTile(String species, List<Bird> birds){
    List<Bird> selectedBirds = birds
        .where((Bird bird) =>
    bird.species == species)
        .toList();
    if(selectedBirds.length == 0){return SizedBox.shrink();}
    ListTile list_tile = ListTile(
        title: Text("$species ringed"),
        trailing: Text(selectedBirds.length.toString()));

    return list_tile;
  }

  void showNestsonMap(List<Nest> nests){
    String nestList = nests.map((Nest n) => n.id).toList().join(",");
    globals.search = "{$nestList}";
    Navigator.pushNamed(context, "/map");
  }
}
