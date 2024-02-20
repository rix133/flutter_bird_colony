import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/models/species.dart';
import 'package:provider/provider.dart';

import 'design/experimentDropdown.dart';
import 'design/yearDropdown.dart';
import 'models/experiment.dart';
import 'models/firestoreItemMixin.dart';
import 'models/nest.dart';
import 'models/speciesRawAutocomplete.dart';

class ListNests extends StatefulWidget {
  const ListNests({Key? key}) : super(key: key);

  @override
  State<ListNests> createState() => _ListNestsState();
}

class _ListNestsState extends State<ListNests> {
  int _selectedYear = DateTime.now().year;
  String? _selectedExperiments;
  String? _selectedSpecies;
  double? _minNestAge;
  double? _maxNestAge;
  double? _minEggAge;
  double? _maxEggAge;
  int? _minEggs;
  int? _maxEggs;
  List<Experiment> allExperiments = [];
  double? _minLocationAccuracy;
  double? _maxLocationAccuracy;
  FocusNode _focusNode = FocusNode();

  SharedPreferencesService? sps;
  List<Nest> nests = [];
  CollectionReference nestCollection =
      FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  TextEditingController searchController = TextEditingController();
  Stream<QuerySnapshot> _nestsStream = Stream.empty();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      _nestsStream = nestCollection.snapshots();
      FirebaseFirestore.instance.collection('experiments').get().then((value) {
        allExperiments =
            value.docs.map((e) => Experiment.fromQuerySnapshot(e)).toList();
      });

      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
    _focusNode.dispose();

  }

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

  getDownloadButton(BuildContext context, SharedPreferencesService? sps) {
    if (sps == null) {
      return Container();
    }
    if (sps.isAdmin == false) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: IconButton(
          onPressed: () {
            FSItemMixin().downloadExcel(nests, "nests");
          },
          icon: Icon(Icons.download),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey))),
    );
  }

  Padding getMinMaxInput(BuildContext context, String label, Function(String) minFun, Function(String) maxFun, double? min, double? max) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        Text(label),
        SizedBox(width: 10),
        Expanded(child:TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Min",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
            ),
          ),
          initialValue: min?.toString() ?? "",
          onChanged: minFun
        )),
        SizedBox(width: 10),
        Expanded(child:TextFormField(
          keyboardType: TextInputType.number,
            initialValue: max?.toString() ?? "",
          decoration: InputDecoration(
            labelText: "Max",

            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
            ),
          ),
          onChanged: maxFun
        )),
      ]),
    );
  }

  updateYearFilter(int value) {
   nestCollection =
    FirebaseFirestore.instance.collection(value.toString());
    setState(() {
      _nestsStream = nestCollection.snapshots();
      _selectedYear = value;
    });
  }
  updateExperimentFilter(String? value) {
    setState(() {
      _selectedExperiments = value;
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

  void clearFilters() {
    setState(() {
      _selectedYear = DateTime.now().year;
      _selectedExperiments = null;
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

  Widget yearInput() {
    return DropdownButton<int>(
      value: _selectedYear,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: List<int>.generate(DateTime.now().year - 2022 + 1,
          (int index) => index + 2022).map((int year) {
        return DropdownMenuItem<int>(
          value: year,
          child: Text(year.toString(),
              style: TextStyle(color: Colors.deepPurpleAccent)),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedYear = newValue!;
        });
      },
    );
  }

  Widget experimentInput() {
    return DropdownButton<String>(
      value: _selectedExperiments,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: allExperiments.map((Experiment e) {
        return DropdownMenuItem<String>(
          value: e.name,
          child: Text(e.name,
              style: TextStyle(color: Colors.deepPurpleAccent)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedExperiments = newValue;
        });
      },
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
              YearDropdown(
                selectedYear: _selectedYear,
                onChanged: updateYearFilter,
              ),

              ExperimentDropdown(
                allExperiments: allExperiments,
                selectedExperiment: _selectedExperiments,
                onChanged: updateExperimentFilter,
              ),
              SpeciesRawAutocomplete(
                  returnFun: (Species s) {
                    _selectedSpecies = s.english;
                    setState(() {});
                  },
                  species: Species(english: _selectedSpecies?? "", local: '', latinCode: ''),
                  speciesList: sps?.defaultSpeciesList ?? [],
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

  bool filterByExperiments(Nest e) {
    if (_selectedExperiments == null) return true;
    return e.experiments?.map((e) => e.name).contains(_selectedExperiments) ??
        false;
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

    List<Nest> getFilteredNests(AsyncSnapshot snapshot) {
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

  Widget build(BuildContext context) {
    return  Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                SizedBox(height: 20,),
                Row(children: [
                  Expanded(
                      child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: "Search",
                      hintText: "Search by nest or experiment",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                    ),
                  )),
                  ElevatedButton.icon(
                      onPressed: () => openFilterDialog(context),
                      icon: Icon(Icons.filter_alt),
                      label: Padding(
                          child: Text("Filter", style: TextStyle(fontSize: 18)),
                          padding: EdgeInsets.all(12)),
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.grey))),
                ]),
                SizedBox(
                  height: 20,
                ),
                Expanded(
                    child: StreamBuilder(
                        stream: _nestsStream,
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            nests = getFilteredNests(snapshot);
                            return ListView(
                              children: [
                                ...nests.map((Nest e) => e.getListTile(context))
                              ],
                            );
                          } else {
                            return Container(
                                padding: EdgeInsets.all(40.0),
                                child: Text("loading nests..."));
                          }
                        })),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        getAddButton(context),
                        getDownloadButton(context, sps)
                      ],
                    )),
              ],
            ));
  }
}

