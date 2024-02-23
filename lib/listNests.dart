import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/listScreenWidget.dart';
import 'package:kakrarahu/models/species.dart';

import 'models/firestoreItemMixin.dart';
import 'models/nest.dart';
import 'design/speciesRawAutocomplete.dart';

class ListNests extends ListScreenWidget<Nest> {
  const ListNests({Key? key}) : super(key: key, title: 'nests with eggs', icon: Icons.home);

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


  List<Nest> nests = [];
 CollectionReference? collection = FirebaseFirestore.instance.collection(DateTime.now().year.toString());



  @override
  void dispose() {
    nests.forEach((n) {
      n.dispose();
    });
    super.dispose();
  }

  @override
  getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, "/map", arguments: {'nest_ids': nests.map((e) => e.id).toList()});
          },
          icon: Icon(Icons.map),
          label: Padding(
              child: Text("Show nests", style: TextStyle(fontSize: 18)),
              padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey))),
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
              getMinMaxInput(context, "First egg age", updateMinEggAge, updateMaxEggAge, _minEggAge, _maxEggAge),
              getMinMaxInput(context, "Nest age", updateMinNestAge, updateMaxNestAge, _minNestAge, _maxNestAge),
              getMinMaxInput(context, "Loc accuracy", updateMinLocationAccuracy, updateMaxLocationAccuracy, _minLocationAccuracy, _maxLocationAccuracy),

            ])),
            actions: [
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
    collection =
        FirebaseFirestore.instance.collection(value.toString());
    setState(() {
      stream = collection?.snapshots() ?? Stream.empty();
      selectedYear = value;
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
      searchController.clear();
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
    int? eggCount = await e.eggCount();
    if (_minEggs == null) return eggCount < _maxEggs! - 1;
    if (_maxEggs == null) return eggCount > _minEggs! - 1;
    return eggCount > _minEggs! - 1 && eggCount < _maxEggs! - 1;
  }

    List<Nest> getFilteredItems(AsyncSnapshot snapshot) {
    List<Nest> nests =
        snapshot.data!.docs.map<Nest>((e) => Nest.fromDocSnapshot(e)).toList();

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
    return(FSItemMixin().downloadExcel(nests, "nests"));
  }
}

