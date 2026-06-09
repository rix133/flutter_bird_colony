import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/services/birdsService.dart';
import 'package:flutter_bird_colony/services/nestsService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/firestore/bird.dart';

class Statistics extends StatefulWidget {
  final FirebaseFirestore firestore;
  const Statistics({Key? key, required this.firestore}) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  int _selectedYear = DateTime.now().year;
  final TextEditingController _textFilterController = TextEditingController();
  final TextEditingController _lastDaysController =
      TextEditingController(text: "7");
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
    DropdownMenuItem(
        child: Text("All", style: TextStyle(color: Colors.deepPurpleAccent)),
        value: "All"),
    DropdownMenuItem(
        child: Text("Today", style: TextStyle(color: Colors.deepPurpleAccent)),
        value: "Today"),
    DropdownMenuItem(
        child:
            Text("Yesterday", style: TextStyle(color: Colors.deepPurpleAccent)),
        value: "Yesterday"),
    DropdownMenuItem(
        child: Text("Last X days",
            style: TextStyle(color: Colors.deepPurpleAccent)),
        value: "Last X days")
  ];
  String dropdownValue = "All";

  List<DropdownMenuItem<String>> people = <DropdownMenuItem<String>>[
    DropdownMenuItem(
        child:
            Text("Everybody", style: TextStyle(color: Colors.deepPurpleAccent)),
        value: "Everybody"),
    DropdownMenuItem(
        child: Text("Me", style: TextStyle(color: Colors.deepPurpleAccent)),
        value: "Me"),
    DropdownMenuItem(
        child: Text("Person", style: TextStyle(color: Colors.deepPurpleAccent)),
        value: "Person")
  ];
  String dropdownValuePeople = "Everybody";

  Widget _tileMaterial(ListTile tile) {
    return Material(color: Colors.transparent, child: tile);
  }

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
    _textFilterController.dispose();
    _lastDaysController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int get _lastDays {
    final parsed = int.tryParse(_lastDaysController.text);
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  DateTimeRange _birdDateRange() {
    final today = _dateOnly(DateTime.now());
    if (dropdownValue == "Today") {
      return DateTimeRange(start: today, end: today.add(Duration(days: 1)));
    }
    if (dropdownValue == "Yesterday") {
      final yesterday = today.subtract(Duration(days: 1));
      return DateTimeRange(start: yesterday, end: today);
    }
    if (dropdownValue == "Last X days") {
      return DateTimeRange(
          start: today.subtract(Duration(days: _lastDays - 1)),
          end: today.add(Duration(days: 1)));
    }
    return DateTimeRange(
        start: DateTime(_selectedYear), end: DateTime(_selectedYear + 1));
  }

  DateTimeRange? _narrowDateRange() {
    if (dropdownValue == "All") {
      return null;
    }
    return _birdDateRange();
  }

  String get _personFilter => dropdownValuePeople == "Person"
      ? _textFilterController.text.trim().toLowerCase()
      : "";

  _refreshStreams() {
    _nestsStream =
        nestsService?.watchItems(yearToNestCollectionName(_selectedYear)) ??
            Stream.empty();
    DateTimeRange range = _birdDateRange();

    if (birdsCollection != null) {
      birdsQuery = birdsCollection!
          .where("ringed_date", isGreaterThanOrEqualTo: range.start)
          .where("ringed_date", isLessThan: range.end);
    }
  }

  bool _matchesDate(DateTime date) {
    final range = _narrowDateRange();
    if (range == null) {
      return true;
    }
    final dateOnly = _dateOnly(date);
    return !dateOnly.isBefore(range.start) && dateOnly.isBefore(range.end);
  }

  bool _matchesSelectedPerson(String? responsible) {
    if (dropdownValuePeople == "Me") {
      return responsible == username;
    }
    if (_personFilter.isEmpty) {
      return true;
    }
    return (responsible ?? "").toLowerCase().contains(_personFilter);
  }

  Widget buildNestList(List<Nest> nests) {
    if (nests.length != 0) {
      nests = nests
          .where((Nest n) => _matchesDate(n.last_modified ?? n.discover_date))
          .toList();
      nests = nests
          .where((Nest n) => _matchesSelectedPerson(n.responsible))
          .toList();
      return ListView(
        children: [
          _tileMaterial(ListTile(
              title: Text("Total nests"),
              trailing: Text(nests.length.toString()),
              onLongPress: () =>
                  _showNestsIfAllowed("Total nests", nests, isTotal: true))),
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
                              final maxYear =
                                  DateTime.now().year > _selectedYear
                                      ? DateTime.now().year
                                      : _selectedYear;
                              final years = maxYear >= startYear
                                  ? List<int>.generate(maxYear - startYear + 1,
                                      (int index) => index + startYear)
                                  : <int>[maxYear];
                              return years;
                            })()
                                .map((int year) {
                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString(),
                                    style: TextStyle(
                                        color: Colors.deepPurpleAccent)),
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
                    if (dropdownValue == "Last X days")
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        child: TextField(
                          key: Key("statisticsLastDaysField"),
                          controller: _lastDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: "Days"),
                          onChanged: (value) {
                            setState(() {
                              _refreshStreams();
                            });
                          },
                        ),
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
                                if (dropdownValuePeople != "Person") {
                                  _textFilterController.clear();
                                }
                                _refreshStreams();
                              });
                            },
                          )
                        ]),
                    if (dropdownValuePeople == "Person")
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        child: TextField(
                          key: Key("statisticsNameFilterField"),
                          controller: _textFilterController,
                          decoration: InputDecoration(
                            labelText: "Person name filter",
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                      color: Theme.of(context)
                          .scaffoldBackgroundColor, // Replace with your desired color
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
    List<Nest> selectedNests =
        nests.where((Nest nest) => nest.species == species).toList();
    if (selectedNests.length == 0) {
      return SizedBox.shrink();
    }
    ListTile list_tile = ListTile(
        leading: IconButton(
            onPressed: () => showNestsonMap(selectedNests),
            icon: Icon(Icons.map)),
        title: Text(species == "" ? "No species nests" : "$species nests"),
        trailing: Text(selectedNests.length.toString()),
        onLongPress: () => _showNestsIfAllowed(
            species == "" ? "No species nests" : "$species nests",
            selectedNests),
        onTap: () => null);

    return _tileMaterial(list_tile);
  }

  List<Bird> _filterLocalBirds(String species) {
    List<Bird> selectedBirds = birdsService!.items;
    if (species != "Total") {
      selectedBirds =
          selectedBirds.where((Bird bird) => bird.species == species).toList();
    }
    //filter by selected year
    selectedBirds = selectedBirds
        .where((Bird bird) => bird.ringed_date.year == _selectedYear)
        .toList();

    selectedBirds = selectedBirds
        .where((Bird bird) => _matchesDate(bird.ringed_date))
        .toList();

    selectedBirds = selectedBirds
        .where((Bird bird) => _matchesSelectedPerson(bird.responsible))
        .toList();
    return selectedBirds;
  }

  Widget getLocalBirdsListTile(String species) {
    List<Bird> selectedBirds = _filterLocalBirds(species);
    if (selectedBirds.length == 0 && species != "Total") {
      return SizedBox.shrink();
    }
    ListTile list_tile = ListTile(
        title: Text(species == "" ? "No species birds" : "$species ringed"),
        trailing: Text(selectedBirds.length.toString()),
        onLongPress: () => _showBirdsIfAllowed(
            species == "" ? "No species birds" : "$species ringed", species,
            localBirds: selectedBirds));

    return _tileMaterial(list_tile);
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

      if (_personFilter.isNotEmpty) {
        return FutureBuilder<QuerySnapshot<Object?>>(
          future: birdsQuery?.get(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
            if (snapshot.hasData) {
              List<Bird> birds = snapshot.data!.docs
                  .map((doc) => Bird.fromDocSnapshot(doc))
                  .where((bird) => _matchesSelectedPerson(bird.responsible))
                  .toList();
              int count = birds.length;
              if (count == 0 && species != "Total") {
                return SizedBox.shrink();
              }
              return _tileMaterial(ListTile(
                title: Text("$species ringed"),
                trailing: Text(count.toString()),
                onLongPress: () => _showBirdsIfAllowed(
                    "$species ringed", species,
                    localBirds: birds),
              ));
            } else if (snapshot.hasError) {
              return Text('Error: getting $species data');
            } else {
              return SizedBox.shrink();
            }
          },
        );
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
            return _tileMaterial(ListTile(
              title: Text("$species ringed"),
              trailing: Text(count.toString()),
              onLongPress: () => _showBirdsIfAllowed("$species ringed", species,
                  birdsQuery: birdsQuery),
            ));
          } else if (snapshot.hasError) {
            return Text('Error: getting $species data');
          } else {
            return SizedBox.shrink();
          }
        },
      );
    }
  }

  bool _isBroadTotalSelection({required bool isTotal}) {
    final hasUserFilter =
        dropdownValuePeople == "Me" || _personFilter.isNotEmpty;
    return isTotal && dropdownValue == "All" && !hasUserFilter;
  }

  Future<void> _showNarrowFilterDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text("Narrow filters first"),
              content: Text(
                  "Use a date, user, person name, or species filter before opening all items."),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.pop(context), child: Text("OK"))
              ],
            ));
  }

  Future<void> _showNestsIfAllowed(String title, List<Nest> nests,
      {bool isTotal = false}) async {
    if (_isBroadTotalSelection(isTotal: isTotal)) {
      await _showNarrowFilterDialog();
      return;
    }
    await _showNestsDialog(title, nests);
  }

  Future<void> _showNestsDialog(String title, List<Nest> nests) async {
    final idsText = _copyableIdsText(
        nests.map((nest) => nest.id ?? nest.name).where((id) => id.isNotEmpty));
    await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: nests.isEmpty
                    ? Center(child: Text("No nests"))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${nests.length} nests"),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 90,
                            child: SingleChildScrollView(
                                child: SelectableText(idsText)),
                          ),
                          Divider(),
                          Expanded(
                            child: ListView(
                              children: nests
                                  .map((nest) => Material(
                                      color: Colors.transparent,
                                      child: nest.getListTile(
                                          context, widget.firestore,
                                          groups:
                                              sps?.markerColorGroups ?? [])))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                ElevatedButton(
                    key: Key("copyStatisticsNestIdsButton"),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: idsText)),
                    child: Text("Copy IDs")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"))
              ],
            ));
  }

  Future<void> _showBirdsIfAllowed(String title, String species,
      {List<Bird>? localBirds, Query? birdsQuery}) async {
    if (_isBroadTotalSelection(isTotal: species == "Total")) {
      await _showNarrowFilterDialog();
      return;
    }

    List<Bird> birds = localBirds ?? [];
    if (localBirds == null && birdsQuery != null) {
      final snapshot = await birdsQuery.get();
      birds = snapshot.docs
          .map((doc) => Bird.fromDocSnapshot(doc))
          .where((bird) => _matchesSelectedPerson(bird.responsible))
          .toList();
    }
    if (!mounted) return;
    await _showBirdsDialog(title, birds);
  }

  Future<void> _showBirdsDialog(String title, List<Bird> birds) async {
    final idsText = _copyableIdsText(birds.map((bird) => bird.id ?? bird.band));
    await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: birds.isEmpty
                    ? Center(child: Text("No birds"))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${birds.length} birds"),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 90,
                            child: SingleChildScrollView(
                                child: SelectableText(idsText)),
                          ),
                          Divider(),
                          Expanded(
                            child: ListView(
                              children: birds
                                  .map((bird) => Material(
                                      color: Colors.transparent,
                                      child: bird.getListTile(
                                          context, widget.firestore,
                                          groups:
                                              sps?.markerColorGroups ?? [])))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                ElevatedButton(
                    key: Key("copyStatisticsBirdIdsButton"),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: idsText)),
                    child: Text("Copy IDs")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"))
              ],
            ));
  }

  String _copyableIdsText(Iterable<String> ids) {
    final sortedIds = ids.where((id) => id.isNotEmpty).toSet().toList()..sort();
    return sortedIds.join("\n");
  }

  void showNestsonMap(List<Nest> nests) {
    List<String> nestIds = nests.map((Nest n) => n.id ?? "").toList();
    Navigator.pushNamed(context, '/mapNests',
        arguments: {"nest_ids": nestIds, "year": _selectedYear});
  }
}
