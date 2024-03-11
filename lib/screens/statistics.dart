
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestore/bird.dart';
import 'package:kakrarahu/models/firestore/nest.dart';
import 'package:kakrarahu/models/firestore/species.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

class Statistics extends StatefulWidget {
  final FirebaseFirestore firestore;
  const Statistics({Key? key, required this.firestore})  : super(key: key);


  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  var today = DateTime.now().toIso8601String().split("T")[0];
  int _selectedYear = DateTime.now().year;
  SharedPreferencesService? sps;
  LocalSpeciesList _speciesList = LocalSpeciesList();

  CollectionReference? birds;
  CollectionReference? nests;
  Query? birdsQuery;
  Stream<QuerySnapshot> _nestsStream =  Stream.empty();
  Stream<QuerySnapshot> _birdsStream = Stream.empty();

  String username = "";


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
  void initState() {
    super.initState();
    birds = widget.firestore.collection('Birds');
    nests = widget.firestore.collection(_selectedYear.toString());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      _speciesList = sps!.speciesList;
      username = sps!.userName;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _refreshStreams() {
    if(_selectedYear == 2022){
      nests = widget.firestore.collection("Nest");
    } else {
      nests = widget.firestore.collection(_selectedYear.toString());
    }
    DateTime startDate = DateTime(_selectedYear);
    DateTime endDate = DateTime(_selectedYear + 1);

    if(birds != null){
      birdsQuery = birds!
          .where("ringed_date", isGreaterThanOrEqualTo: startDate)
          .where("ringed_date", isLessThan: endDate);
    }


    _nestsStream = nests?.snapshots() ?? Stream.empty();
    _birdsStream = birdsQuery?.snapshots() ?? Stream.empty();
  }

  Widget build(BuildContext context) {
    _refreshStreams();

    return Scaffold(
        appBar: AppBar(
          title: Text("Some statistics", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.amberAccent,
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Select year:'),
                Container(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List<int>.generate(DateTime.now().year - 2022 + 1, (int index) => index + 2022)
                      .map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString(), style: TextStyle(color: Colors.deepPurpleAccent)),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedYear = newValue!;
                    });
                  },
                )
              ]),
             Row(
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
                            .map((DocumentSnapshot e) => Nest.fromDocSnapshot(e))
                            .toList();
                        nests = nests.where((Nest n) => n.timeSpan(dropdownValue)).toList();
                        nests = nests.where((Nest n) => n.people(dropdownValuePeople, username)).toList();
                        return ListView(

                          children: [
                            ListTile(
                                title: Text("Total nests"),
                                trailing: Text(nests.length.toString())),
                            getNestListTile("Common Gull", nests, experimental: true),
                            ..._speciesList.species.map((Species sp) => getNestListTile(sp.english, nests)).toList(),
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
                            .map((DocumentSnapshot e) => Bird.fromDocSnapshot(e))
                            .toList();
                        birds = birds.where((Bird b) => b.timeSpan(dropdownValue)).toList();
                        birds = birds.where((Bird b) => b.people(dropdownValuePeople, username)).toList();
                        return ListView(
                          children: [
                            ListTile(
                                title: Text("Total ringed"),
                                trailing: Text(birds.length.toString())),
                            ..._speciesList.species.map((Species sp) => getBirdsListTile(sp.english, birds)).toList(),
                          ],
                        );
                      } else {
                        return Container(
                            padding: EdgeInsets.all(40.0),
                            child: Text("loading birds..."));
                      }
                    }))
          ],
        )));
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
    Set<String?> nestList = nests.map((Nest n) => n.id).toSet();
    //remove nulls
    nestList.removeWhere((element) => element == null);
    Navigator.pushNamed(context, '/mapNests', arguments: {"nest_ids": nestList});
  }
}
