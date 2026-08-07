import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:provider/provider.dart';

import '../../design/listScreenWidget.dart';
import '../../design/speciesRawAutocomplete.dart';
import '../../models/firestore/firestoreItem.dart';
import '../../services/birdsService.dart';

class ListBirds extends ListScreenWidget<Bird> {
  const ListBirds(
      {Key? key,
      required FirebaseFirestore firestore,
      ExcelDownloadCallback? excelDownloadCallback})
      : super(
            key: key,
            title: 'birds',
            icon: Icons.nat_sharp,
            firestore: firestore,
            excelDownloadCallback: excelDownloadCallback);

  @override
  ListScreenWidgetState<Bird> createState() => _ListBirdsState();
}

class _ListBirdsState extends ListScreenWidgetState<Bird> {
  String? _selectedSpecies;
  int? _selectedAge;

  @override
  String? get experimentFilterType => "bird";

  @override
  bool get shouldLoadData =>
      activeExperimentFilter != null || (_selectedSpecies?.isNotEmpty ?? false);

  @override
  bool get supportsAllYearDownload => true;

  @override
  String get allYearDownloadType => "birds";

  @override
  String get dataLoadBlockedMessage =>
      "Select a species or bird experiment to show birds.";

  @override
  String get dataQueryKeySuffix => "species:${_selectedSpecies ?? ''}";

  @override
  Query<Map<String, dynamic>> baseDataQuery() {
    Query<Map<String, dynamic>> query = super.baseDataQuery();
    if (activeExperimentFilter == null &&
        (_selectedSpecies?.isNotEmpty ?? false)) {
      query = query
          .where("species", isEqualTo: _selectedSpecies)
          .where("ringed_date",
              isGreaterThanOrEqualTo: DateTime(selectedYear, 1, 1))
          .where("ringed_date", isLessThan: DateTime(selectedYear + 1, 1, 1));
    }
    return query;
  }

  @override
  void initState() {
    collectionName = "Birds";
    fsService = Provider.of<BirdsService>(context, listen: false);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/editBird');
          },
          icon: Icon(Icons.add),
          label: Padding(
              child: Text("Add adult", style: TextStyle(fontSize: 18)),
              padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey))),
    );
  }

  void openFilterDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text("Filter"),
            content: SingleChildScrollView(
                child: Column(children: [
              yearInput(context),
              experimentInput(context),
              SpeciesRawAutocomplete(
                  returnFun: (Species s) {
                    _selectedSpecies = s.english;
                    refreshDataStream();
                    setState(() {});
                  },
                  species: Species(
                      english: _selectedSpecies ?? "",
                      local: '',
                      latinCode: ''),
                  speciesList: sps?.speciesList ?? LocalSpeciesList(),
                  borderColor: Colors.white38,
                  bgColor: Colors.amberAccent,
                  labelColor: Colors.grey),
            ])),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    clearFilters();
                  },
                  child: Text("Clear all")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Close"))
            ],
          );
        });
  }

  bool filterByYear(Bird e) {
    return e.nest_year == selectedYear || e.ringed_date.year == selectedYear;
  }

  updateYearFilter(int value) {
    selectedYear = value;
  }

  @override
  void clearFilters() {
    super.clearFilters();
    setState(() {
      _selectedSpecies = null;
      _selectedAge = null;
    });
    refreshDataStream();
  }

  bool filterByText(Bird e) {
    return e.band.toLowerCase().contains(searchController.text.toLowerCase()) ||
        (e.color_band != null
            ? e.color_band!
                .toLowerCase()
                .contains(searchController.text.toLowerCase())
            : false);
  }

  bool filterBySpecies(Bird e) {
    if (_selectedSpecies == null) return true;
    return e.species == _selectedSpecies;
  }

  bool filterByAge(Bird e) {
    if (_selectedAge == null) return true;
    return e.ageInYears() == _selectedAge;
  }

  @override
  Future<void> executeDownload() {
    return exportToExcel(items, "birds");
  }

  @override
  Future<List<FirestoreItem>> loadAllItemsForSelectedYear() async {
    final birds = widget.firestore.collection("Birds");
    final start = DateTime(selectedYear, 1, 1);
    final end = DateTime(selectedYear + 1, 1, 1);
    final snapshots = await Future.wait([
      birds
          .where("ringed_date", isGreaterThanOrEqualTo: start)
          .where("ringed_date", isLessThan: end)
          .get(),
      birds.where("nest_year", isEqualTo: selectedYear).get(),
    ]);

    final birdsById = <String, Bird>{};
    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        birdsById[document.id] = Bird.fromDocSnapshot(document);
      }
    }

    final allBirds = birdsById.values.toList()
      ..sort((a, b) => a.band.compareTo(b.band));
    return allBirds;
  }

  List<Bird> getFilteredItems(List<FirestoreItem> items) {
    List<Bird> birds = items as List<Bird>;

    birds = birds.where(filterByText).toList();
    birds = birds.where(filterByExperiments).toList();
    birds = birds.where(filterByYear).toList();
    birds = birds.where(filterBySpecies).toList();
    birds = birds.where(filterByAge).toList();

    return birds;
  }
}
