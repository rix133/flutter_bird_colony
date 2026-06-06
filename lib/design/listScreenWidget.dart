import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/experimentedItem.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/services/experimentsService.dart';
import 'package:flutter_bird_colony/services/firestoreItemService.dart';
import 'package:provider/provider.dart';

import '../models/firestore/experiment.dart';
import '../services/sharedPreferencesService.dart';

abstract class ListScreenWidget<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final FirebaseFirestore firestore;
  const ListScreenWidget(
      {Key? key,
      required this.title,
      required this.icon,
      required this.firestore})
      : super(key: key);

  @override
  ListScreenWidgetState<T> createState();
}

abstract class ListScreenWidgetState<T> extends State<ListScreenWidget<T>> {
  int selectedYear = DateTime.now().year;
  String? selectedExperimentId;
  Stream<List<FirestoreItem>> stream = Stream.empty();
  ExperimentsService? experimentsService;
  Stream<List<Experiment>> experimentStream = Stream.empty();
  StreamSubscription<List<Experiment>>? _experimentSubscription;
  TextEditingController searchController = TextEditingController();
  bool downloading = false;
  String collectionName = "";
  FirestoreItemService? fsService;

  SharedPreferencesService? sps;

  List<FirestoreItem> get items => getFilteredItems(fsService?.items ?? []);

  bool get supportsExperimentFilter => true;

  String? get experimentFilterType => null;

  @override
  void dispose() {
    _experimentSubscription?.cancel();
    super.dispose();
    searchController.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      experimentsService =
          Provider.of<ExperimentsService>(context, listen: false);
      selectedYear = sps?.selectedYear ?? selectedYear;
      if (supportsExperimentFilter) {
        final defaultExperiment = sps?.defaultDataExperiment ?? '';
        selectedExperimentId =
            defaultExperiment.isEmpty ? null : defaultExperiment;
      }
      updateYearFilter(selectedYear);
      if (supportsExperimentFilter) {
        experimentStream =
            experimentsService?.watchItems("experiments") ?? Stream.empty();
        _experimentSubscription = experimentStream.listen((experiments) {
          _clearUnavailableExperimentSelection(experiments);
          _refreshDataStream();
          if (mounted) {
            setState(() {});
          }
        });
      }
      if (!supportsExperimentFilter || selectedExperimentId == null) {
        _refreshDataStream();
      }

      setState(() {});
    });
  }

  void clearFilters() {
    final defaultYear = sps?.selectedYear ?? DateTime.now().year;
    setState(() {
      selectedYear = defaultYear;
      selectedExperimentId = null;
      searchController.clear();
    });
    updateYearFilter(defaultYear);
    _refreshDataStream();
  }

  bool filterByExperiments(ExperimentedItem e) {
    if (selectedExperimentId == null) return true;
    final selectedExperiment = _selectedExperiment();
    return e.experiments?.any((experiment) =>
            experiment.id == selectedExperimentId ||
            experiment.name == selectedExperimentId ||
            (selectedExperiment != null &&
                experiment.name == selectedExperiment.name)) ??
        false;
  }

  List<Experiment> _availableExperiments(List<Experiment> experiments) {
    return experiments.where((experiment) {
      final typeMatches = experimentFilterType == null ||
          experiment.type == experimentFilterType;
      final yearMatches =
          experiment.year == null || experiment.year == selectedYear;
      return typeMatches && yearMatches;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _clearUnavailableExperimentSelection(List<Experiment> experiments) {
    if (!supportsExperimentFilter || selectedExperimentId == null) {
      return;
    }
    if (!_availableExperiments(experiments)
        .any((experiment) => experiment.id == selectedExperimentId)) {
      selectedExperimentId = null;
    }
  }

  Experiment? _selectedExperiment() {
    if (selectedExperimentId == null) {
      return null;
    }
    for (final experiment
        in _availableExperiments(experimentsService?.items ?? [])) {
      if (experiment.id == selectedExperimentId ||
          experiment.name == selectedExperimentId) {
        return experiment;
      }
    }
    return null;
  }

  Query<Map<String, dynamic>> _baseDataQuery() {
    return widget.firestore.collection(collectionName);
  }

  List<Query<Map<String, dynamic>>> _dataQueries() {
    Query<Map<String, dynamic>> query = _baseDataQuery();
    final selectedExperiment = _selectedExperiment();
    if (supportsExperimentFilter && selectedExperiment != null) {
      final queries = <Query<Map<String, dynamic>>>[];
      final experimentId = selectedExperiment.id;
      if (experimentId != null && experimentId.isNotEmpty) {
        queries.add(query.where('experimentIds', arrayContains: experimentId));
      }
      queries.add(query.where('experiments',
          arrayContains: selectedExperiment.toSimpleJson()));
      return queries;
    }
    return [query];
  }

  void _refreshDataStream() {
    if (collectionName.isEmpty || fsService == null) {
      stream = Stream.empty();
      return;
    }
    final selectedExperiment = _selectedExperiment();
    final key =
        "$collectionName|experiment:${selectedExperiment?.id ?? selectedExperiment?.name ?? 'all'}|${selectedExperiment?.toSimpleJson().toString() ?? ''}";
    stream = fsService?.watchQueries(key, _dataQueries()) ?? Stream.empty();
  }

  Widget yearInput(BuildContext context) {
    const startYear = 2022;
    final maxYear =
        DateTime.now().year > selectedYear ? DateTime.now().year : selectedYear;
    final years = maxYear >= startYear
        ? List<int>.generate(
            maxYear - startYear + 1, (int index) => index + startYear)
        : <int>[maxYear];
    return DropdownButton<int>(
      value: selectedYear,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: years.map((int year) {
        return DropdownMenuItem<int>(
          value: year,
          child: Text(year.toString(),
              style: TextStyle(color: Colors.deepPurpleAccent)),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          selectedYear = newValue ?? selectedYear;
          updateYearFilter(selectedYear);
          _clearUnavailableExperimentSelection(experimentsService?.items ?? []);
          _refreshDataStream();
          Navigator.pop(context);
        });
      },
    );
  }

  updateYearFilter(int value);

  Future<void> executeDownload();

  Widget getAddButton(BuildContext context);

  Future<bool> _downloadConfirmationDialog(BuildContext context) {
    bool admin = sps?.isAdmin ?? false;
    if (admin) {
      return Future.value(true);
    } else {
      return showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: Text("Download"),
              content: Text(
                  "To get selected ${widget.title} to Excel contact an administrator."),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text("OK", style: TextStyle(color: Colors.black))),
              ],
            );
          }).then((value) => value ?? false);
    }
  }

  getDownloadButton(BuildContext context, SharedPreferencesService? sps) {
    if (sps == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: downloading
          ? CircularProgressIndicator()
          : IconButton(
              onPressed: () {
                setState(() {
                  downloading = true;
                });
                _downloadConfirmationDialog(context).then((bool value) => {
                      if (value)
                        {
                          executeDownload().then((value) => setState(() {
                                downloading = false;
                              })),
                        }
                      else
                        {
                          setState(() {
                            downloading = false;
                          })
                        }
                    });
              },
              icon: Icon(Icons.download),
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.grey))),
    );
  }

  bool filterByText(T item);

  void openFilterDialog(BuildContext context);

  List<FirestoreItem> getFilteredItems(List<FirestoreItem> items);

  Widget listAllItems(BuildContext context, List<FirestoreItem> inputItems) {
    // Disable editing when browsing a year different from the app's selected year
    // (unless admin).
    final appYear = sps?.selectedYear ?? DateTime.now().year;
    bool disabled = selectedYear != appYear && !(sps?.isAdmin ?? false);
    //the items need to be asigned for Downlaoding purposes
    List<FirestoreItem> items = getFilteredItems(inputItems);
    return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Material(
              color: Colors.transparent,
              child: items[index].getListTile(context, widget.firestore,
                  disabled: disabled, groups: sps?.markerColorGroups ?? []));
        });
  }

  Widget experimentInput(BuildContext context) {
    return StreamBuilder<List<Experiment>>(
      stream: experimentStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        final experiments = _availableExperiments(snapshot.data!);
        final selectedValue = experiments
                .any((experiment) => experiment.id == selectedExperimentId)
            ? selectedExperimentId
            : null;
        return DropdownButton<String?>(
          key: Key("dataExperimentFilterDropdown"),
          value: selectedValue,
          isExpanded: true,
          style: TextStyle(color: Colors.deepPurpleAccent),
          items: [
            DropdownMenuItem<String?>(
                value: null,
                child: Text("No experiment filter",
                    style: TextStyle(color: Colors.deepPurpleAccent))),
            ...experiments.map((Experiment e) {
              return DropdownMenuItem<String?>(
                value: e.id,
                child: Text(e.name,
                    style: TextStyle(color: Colors.deepPurpleAccent)),
              );
            })
          ],
          onChanged: (String? newValue) {
            setState(() {
              selectedExperimentId = newValue;
              _refreshDataStream();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Row(children: [
                  Expanded(
                      child: TextField(
                    key: Key("searchTextField"),
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: "Search",
                      hintText: "Search by band or nests",
                      prefixIcon: Icon(Icons.search),
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
                              WidgetStateProperty.all(Colors.grey))),
                ]),
                SizedBox(
                  height: 20,
                ),
                Expanded(
                    child: StreamBuilder(
                        stream: stream,
                        builder: (context,
                            AsyncSnapshot<List<FirestoreItem>> snapshot) {
                          if (snapshot.hasData) {
                            return (listAllItems(context, snapshot.data!));
                          } else if (snapshot.hasError) {
                            return Container(
                                padding: EdgeInsets.all(40.0),
                                child: Text("Error loading items"));
                          } else {
                            if (fsService?.items.length == 0) {
                              return Container(
                                  padding: EdgeInsets.all(40.0),
                                  child: Text("loading items..."));
                            } else {
                              return listAllItems(
                                  context, fsService?.items ?? []);
                            }
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
            )));
  }
}
