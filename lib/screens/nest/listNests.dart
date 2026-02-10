import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/listScreenWidget.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bird_colony/utils/year.dart';

import '../../design/minMaxInput.dart';
import '../../services/nestsService.dart';

class ListNests extends ListScreenWidget<Nest> {
  const ListNests({Key? key, required FirebaseFirestore firestore})
      : super(key: key, title: 'nests with eggs', icon: Icons.home, firestore: firestore);

  @override
  ListScreenWidgetState<Nest> createState() => _ListNestsState();
}


class _ListNestsState extends ListScreenWidgetState<Nest> {
  String? _selectedSpecies;
  double? _minNestAge;
  double? _maxNestAge;
  double? _minEggAge;
  double? _maxEggAge;
  int? _minEggs;
  int? _maxEggs;
  double? _minLocationAccuracy;
  double? _maxLocationAccuracy;





  @override
  void dispose() {
    super.dispose();
  }
  @override
  void initState() {
    collectionName = DateTime.now().year.toString();
    fsService = Provider.of<NestsService>(context, listen: false);
    super.initState();
  }

  @override
  getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          key: Key("showFilteredNestButton"),
          onPressed: () {
            // Get the current items at the time the button is pressed
            List<FirestoreItem> currentItems =
                getFilteredItems(fsService?.items ?? []);
            List<String?> nest_ids =
                currentItems.map((e) => e.id.toString()).toList();
            Navigator.pushNamed(context, '/mapNests', arguments: {
              'nest_ids': nest_ids,
              "year": selectedYear.toString()
            });
          },
          icon: Icon(Icons.map),
          label: Padding(
              child: Text("Show nests", style: TextStyle(fontSize: 18)),
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
            content: SingleChildScrollView(child:Column(children: [
              yearInput(context),
              experimentInput(context),
              SpeciesRawAutocomplete(
                  returnFun: (Species s) {
                    _selectedSpecies = s.english;
                    setState(() {});
                  },
                  species: Species(english: _selectedSpecies?? "", local: '', latinCode: ''),
                  speciesList: sps?.speciesList ?? LocalSpeciesList(),
                  borderColor: Colors.white38,
                  bgColor: Colors.amberAccent,
                  labelColor: Colors.grey),
              MinMaxInput(
                  label: "First egg age",
                  minFun: updateMinEggAge,
                  maxFun: updateMaxEggAge,
                  min: _minEggAge,
                  max: _maxEggAge),
              MinMaxInput(
                  label: "Nest age",
                  minFun: updateMinNestAge,
                  maxFun: updateMaxNestAge,
                  min: _minNestAge,
                  max: _maxNestAge),
              MinMaxInput(
                  label: "Loc accuracy",
                  minFun: updateMinLocationAccuracy,
                  maxFun: updateMaxLocationAccuracy,
                  min: _minLocationAccuracy,
                  max: _maxLocationAccuracy),
            ])),
            actions: [
              ElevatedButton(onPressed:
                  (){
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


  updateMinEggAge(String value) {
    setState(() {
      _minEggAge = double.tryParse(value);
    });
  }
  updateMaxEggAge(String value) {
    setState(() {
      _maxEggAge = double.tryParse(value);
    });
  }
  updateMinNestAge(String value) {
    setState(() {
      _minNestAge = double.tryParse(value);
    });
  }
  updateMaxNestAge(String value) {
    setState(() {
      _maxNestAge = double.tryParse(value);
    });
  }
  updateMinLocationAccuracy(String value) {
    setState(() {
      _minLocationAccuracy = double.tryParse(value);
    });
  }
  updateMaxLocationAccuracy(String value) {
    setState(() {
      _maxLocationAccuracy = double.tryParse(value);
    });
  }

  updateYearFilter(int value) {
    collectionName = yearToNestCollectionName(value);
    setState(() {
      stream = fsService?.watchItems(collectionName) ?? Stream.empty();
    });
  }

  void clearFilters() {
    setState(() {
      super.clearFilters();
      _selectedSpecies = null;
      _minNestAge = null;
      _maxNestAge = null;
      _minEggAge = null;
      _maxEggAge = null;
      _minEggs = null;
      _maxEggs = null;
    });
  }



  bool filterByText(Nest e) {
    return e.name.toLowerCase().contains(searchController.text.toLowerCase()) ||
        e.measures.any((element) =>
            !element.isNumber &&
            element.value.toLowerCase().contains(
                searchController.text.toLowerCase())) || // search note texts
        (e.experiments != null
            ? e.experiments!.any((element) => element.name
                .toLowerCase()
                .contains(searchController.text.toLowerCase()))
            : false);
  }


  bool filterBySpecies(Nest e) {
    if (_selectedSpecies == null) return true;
    return e.species == _selectedSpecies;
  }

  bool filterByNestAge(Nest e) {
    if (_minNestAge == null && _maxNestAge == null) return true;
    int timeSinceDiscovery = DateTime.now().difference(e.discover_date).inDays;
    if (_minNestAge == null) return timeSinceDiscovery < _maxNestAge! - 1;
    if (_maxNestAge == null) return timeSinceDiscovery > _minNestAge! - 1;
    return timeSinceDiscovery > _minNestAge! - 1 &&
        timeSinceDiscovery < _maxNestAge! - 1;
  }

  bool filterByFirstEggAge(Nest e) {
    if (_minEggAge == null && _maxEggAge == null && e.first_egg == null) return true;
    if (_minEggAge == null && _maxEggAge == null) return true;
    if (e.first_egg == null) return false;
    int timeSinceFirstEgg = DateTime.now().difference(e.first_egg!).inDays;
    if (_minEggAge == null) return timeSinceFirstEgg < _maxEggAge! - 1;
    if (_maxEggAge == null) return timeSinceFirstEgg > _minEggAge! - 1;
    return timeSinceFirstEgg > _minEggAge! - 1 &&
        timeSinceFirstEgg < _maxEggAge! - 1;
  }

  bool filterByLocationAccuracy(Nest e) {
    if (e.getAccuracy() > 9998) return true;
    if (_minLocationAccuracy == null && _maxLocationAccuracy == null) return true;
    if (_minLocationAccuracy == null) return e.getAccuracy() < _maxLocationAccuracy!;
    if (_maxLocationAccuracy == null) return e.getAccuracy() > _minLocationAccuracy!;
    return e.getAccuracy() > _minLocationAccuracy! && e.getAccuracy() < _maxLocationAccuracy!;
  }

  Future<bool> filterByEggCount(Nest e) async {
    if (_minEggs == null && _maxEggs == null) return true;
    int? eggCount = await e.eggCount(widget.firestore);
    if (_minEggs == null) return eggCount < _maxEggs! - 1;
    if (_maxEggs == null) return eggCount > _minEggs! - 1;
    return eggCount > _minEggs! - 1 && eggCount < _maxEggs! - 1;
  }

  List<Nest> getFilteredItems(List<FirestoreItem> items) {
    List<Nest> nests = items.map((e) => e as Nest).toList();

    nests = nests.where(filterByText).toList();
    nests = nests.where(filterByExperiments).toList();
    nests = nests.where(filterBySpecies).toList();
    nests = nests.where(filterByNestAge).toList();
    nests = nests.where(filterByFirstEggAge).toList();
    nests = nests.where(filterByLocationAccuracy).toList();

    /* Filter nests by egg count asynchronously
    nests = await Future.wait(nests.map((nest) async {
      if (await filterByEggCount(nest)) {
        return nest;
      } else {
        return null;
      }
    })).then((list) => list.whereType<Nest>().toList());
   */
    return nests.toList();
  }

  @override
  Future<void> executeDownload() {
    return (FSItemMixin().downloadExcel(items, "nests", widget.firestore));
  }
}


