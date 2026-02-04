
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/services/birdsService.dart';
import 'package:flutter_bird_colony/services/nestsService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:provider/provider.dart';

import '../models/firestore/bird.dart';

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

  CollectionReference? birdsCollection;

  //CollectionReference? nests;
  Query? birdsQuery;
  NestsService? nestsService;
  BirdsService? birdsService;
  Stream<List<Nest>> _nestsStream = Stream.empty();

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
    birdsCollection = widget.firestore.collection('Birds');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      _selectedYear = sps?.selectedYear ?? _selectedYear;
      nestsService = Provider.of<NestsService>(context, listen: false);
      birdsService = Provider.of<BirdsService>(context, listen: false);
      _speciesList = sps!.speciesList;
      username = sps!.userName;
      _refreshStreams();
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _refreshStreams() {
    _nestsStream = nestsService
            ?.watchItems(yearToNestCollectionName(_selectedYear)) ??
        Stream.empty();
    DateTime startDate = DateTime(_selectedYear);
    DateTime endDate = DateTime(_selectedYear + 1);

    if (birdsCollection != null) {
      if (dropdownValue == "Today") {
        // from 00:00 to 00:00
        startDate = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
        endDate = startDate.add(Duration(days: 1)); // Midnight next day
      }
      birdsQuery = birdsCollection!
          .where("ringed_date", isGreaterThanOrEqualTo: startDate)
          .where("ringed_date", isLessThan: endDate);
    }

  }

  Widget buildNestList(List<Nest> nests) {
    if (nests.length != 0) {
      nests = nests.where((Nest n) => n.timeSpan(dropdownValue)).toList();
      nests = nests
          .where((Nest n) => n.people(dropdownValuePeople, username))
          .toList();
      return ListView(
        children: [
          ListTile(
              title: Text("Total nests"),
              trailing: Text(nests.length.toString())),
          ..._speciesList.species
              .map((Species sp) => getNestListTile(sp.english, nests))
              .toList(),
          getNestListTile("", nests),
        ],
      );
    } else {
      return Container(
          padding: EdgeInsets.all(40.0), child: Text("loading nests..."));
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: (sps?.showAppBar ?? true)
            ? AppBar(
                title: Text('Some statistics'),
              )
            : null,
        body: SafeArea(
            child: Container(
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
                  items: (() {
                    const startYear = 2022;
                    final maxYear = DateTime.now().year > _selectedYear
                        ? DateTime.now().year
                        : _selectedYear;
                    final years = maxYear >= startYear
                        ? List<int>.generate(maxYear - startYear + 1,
                            (int index) => index + startYear)
                        : <int>[maxYear];
                    return years;
                  })().map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString(), style: TextStyle(color: Colors.deepPurpleAccent)),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedYear = newValue!;
                            _refreshStreams();
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
                          _refreshStreams();
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
                      setState(() {
                        dropdownValuePeople = newValue!;
                            _refreshStreams();
                          });
                    },
                  )]),
            Expanded(
                child: StreamBuilder(
                    stream: _nestsStream,
                    builder: (context,
                            AsyncSnapshot<List<Nest>> snapshot_nests) {
                          List<Nest> nests = nestsService?.items ?? [];
                          if (snapshot_nests.hasData) {
                            nests = snapshot_nests.data!;
                          }
                          return buildNestList(nests);
                        })),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            color: Theme.of(context).scaffoldBackgroundColor,  // Replace with your desired color
                child: Row(children: [Text("Banding data:")]),
            ),
            Expanded(
                    child: ListView(
                  children: [
                    getBirdsListTile("Total", birdsQuery),
                    ..._speciesList.species
                        .map((Species sp) =>
                            getBirdsListTile(sp.english, birdsQuery))
                        .toList(),
                  ],
                ))
              ],
                ))));
  }

  void onChangedTimespan(value) {
    //print(value);
  }

  Widget getNestListTile(String species, List<Nest> nests) {
    List<Nest> selectedNests = nests
        .where((Nest nest) =>
    nest.species == species)
        .toList();
    if(selectedNests.length == 0){return SizedBox.shrink();}
    ListTile list_tile = ListTile(
        leading: IconButton(
            onPressed: () => showNestsonMap(selectedNests),
            icon: Icon(Icons.map)),
        title: Text(species == "" ? "No species nests" : "$species nests"),
        trailing: Text(selectedNests.length.toString()),
        onTap: () => null);

    return list_tile;
  }

  Widget getLocalBirdsListTile(String species) {
    List<Bird> selectedBirds = birdsService!.items;
    if (species != "Total") {
      selectedBirds =
          selectedBirds.where((Bird bird) => bird.species == species).toList();
    }
    //filter by selected year
    selectedBirds = selectedBirds
        .where((Bird bird) => bird.ringed_date.year == _selectedYear)
        .toList();

    if (dropdownValue == "Today") {
      selectedBirds = selectedBirds
          .where((Bird bird) =>
              bird.ringed_date.toIso8601String().split("T")[0] == today)
          .toList();
    }

    if (dropdownValuePeople == "Me") {
      selectedBirds = selectedBirds
          .where((Bird bird) => bird.responsible == username)
          .toList();
    }
    if (selectedBirds.length == 0 && species != "Total") {
      return SizedBox.shrink();
    }
    ListTile list_tile = ListTile(
        title: Text(species == "" ? "No species birds" : "$species ringed"),
        trailing: Text(selectedBirds.length.toString()));

    return list_tile;
  }

  Widget getBirdsListTile(String species, Query? birdsQuery) {
    if (birdsService == null) {
      return Text("loading birds...");
    } else {
      if (birdsService!.items.length != 0) {
        return getLocalBirdsListTile(species);
      }
      if (species != "Total") {
        birdsQuery = birdsQuery?.where("species", isEqualTo: species);
      }
      if (dropdownValuePeople == "Me") {
        birdsQuery = birdsQuery?.where("responsible", isEqualTo: username);
      }

      return FutureBuilder<AggregateQuerySnapshot>(
        future: birdsQuery?.count().get(),
        builder: (BuildContext context,
            AsyncSnapshot<AggregateQuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            int count = snapshot.data?.count ?? 0;
            if (count == 0 && species != "Total") {
              return SizedBox.shrink();
            }
            return ListTile(
              title: Text("$species ringed"),
              trailing: Text(count.toString()),
            );
          } else if (snapshot.hasError) {
            return Text('Error: getting $species data');
          } else {
            return SizedBox.shrink();
          }
        },
      );
    }
  }

  void showNestsonMap(List<Nest> nests) {
    List<String> nestIds = nests.map((Nest n) => n.id ?? "").toList();
    Navigator.pushNamed(context, '/mapNests',
        arguments: {"nest_ids": nestIds, "year": _selectedYear});
  }
}
