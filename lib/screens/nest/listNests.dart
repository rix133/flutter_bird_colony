import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/listScreenWidget.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/firestore/egg.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bird_colony/utils/year.dart';

import '../../design/minMaxInput.dart';
import '../../services/nestsService.dart';

enum _FilteredNestExperimentAction { add, remove }

class _FilteredNestExperimentSelection {
  final Experiment experiment;
  final _FilteredNestExperimentAction action;

  const _FilteredNestExperimentSelection(this.experiment, this.action);
}

class ListNests extends ListScreenWidget<Nest> {
  const ListNests(
      {Key? key,
      required FirebaseFirestore firestore,
      ExcelDownloadCallback? excelDownloadCallback})
      : super(
            key: key,
            title: 'nests with eggs',
            icon: Icons.home,
            firestore: firestore,
            excelDownloadCallback: excelDownloadCallback);

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
  int? _minChicks;
  int? _maxChicks;
  double? _minLocationAccuracy;
  double? _maxLocationAccuracy;
  bool _onlyLivingEggs = false;
  bool _filterByEggCount = false;
  bool _filterByChickCount = false;
  final Map<String, List<Egg>> _nestItemsCache = {};
  final Map<String, Future<List<Egg>>> _nestItemsFutures = {};

  @override
  String? get experimentFilterType => "nest";

  @override
  bool get supportsAllYearDownload => true;

  @override
  String get allYearDownloadType => "nests";

  String _nestItemsCacheKey(Nest nest) {
    return "${nest.discover_date.year}/${nest.id ?? nest.name}";
  }

  bool get _usesNestItemFilters =>
      _onlyLivingEggs || _filterByEggCount || _filterByChickCount;

  void _clearNestItemFilterCache() {
    _nestItemsCache.clear();
    _nestItemsFutures.clear();
  }

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
          onPressed: () async {
            // Get the current items at the time the button is pressed
            List<FirestoreItem> currentItems =
                await getFilteredItemsAsync(fsService?.items ?? []);
            List<String?> nest_ids =
                currentItems.map((e) => e.id.toString()).toList();
            if (!mounted) return;
            Navigator.pushNamed(context, '/mapNests', arguments: {
              'nest_ids': nest_ids,
              "year": selectedYear.toString()
            });
          },
          onLongPress: () => addFilteredNestsToExperiment(context),
          icon: Icon(Icons.map),
          label: Padding(
              child: Column(children: [
                Text("Show nests", style: TextStyle(fontSize: 18)),
                Text("(long press for experiments)",
                    style: TextStyle(fontSize: 10))
              ]),
              padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey))),
    );
  }

  Future<void> addFilteredNestsToExperiment(BuildContext context) async {
    List<FirestoreItem> currentItems =
        await getFilteredItemsAsync(fsService?.items ?? []);
    List<String> nestIds = currentItems
        .map((e) => e.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final nestIdsText = _copyableIdsText(nestIds);

    if (!mounted) return;
    if (nestIds.isEmpty) {
      await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                backgroundColor: Colors.black87,
                title: Text("Add to experiment"),
                content: Text("No filtered nests to add."),
                actions: [
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK"))
                ],
              ));
      return;
    }

    QuerySnapshot<Object?> snapshot = await widget.firestore
        .collection('experiments')
        .where('year', isEqualTo: selectedYear)
        .get();
    List<Experiment> experiments =
        snapshot.docs.map((doc) => Experiment.fromDocSnapshot(doc)).where((e) {
      return e.type == 'nest';
    }).toList();
    experiments.sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) return;
    Experiment? selectedExperiment;
    _FilteredNestExperimentSelection? selection =
        await showDialog<_FilteredNestExperimentSelection>(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: Colors.black87,
                  title: Text("Filtered nests and experiment"),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${nestIds.length} filtered nests selected"),
                        SizedBox(height: 8),
                        Expanded(
                          child: experiments.isEmpty
                              ? Text("No nest experiments for $selectedYear.")
                              : RadioGroup<Experiment>(
                                  groupValue: selectedExperiment,
                                  onChanged: (Experiment? value) {
                                    setDialogState(() {
                                      selectedExperiment = value;
                                    });
                                  },
                                  child: ListView(
                                    children: experiments
                                        .map((experiment) =>
                                            RadioListTile<Experiment>(
                                              key: Key(
                                                  "addFilteredNests_${experiment.id ?? experiment.name}"),
                                              title: Text(experiment.name),
                                              subtitle: Text(
                                                  "${nestIds.length} filtered nests selected"),
                                              value: experiment,
                                            ))
                                        .toList(),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                        key: Key("copyFilteredNestIdsButton"),
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: nestIdsText)),
                        child: Text("Copy IDs")),
                    ElevatedButton(
                        key: Key("addFilteredNestsAddButton"),
                        onPressed: selectedExperiment == null
                            ? null
                            : () => Navigator.pop(
                                context,
                                _FilteredNestExperimentSelection(
                                    selectedExperiment!,
                                    _FilteredNestExperimentAction.add)),
                        child: Text("Add")),
                    ElevatedButton(
                        key: Key("addFilteredNestsRemoveButton"),
                        onPressed: selectedExperiment == null
                            ? null
                            : () => Navigator.pop(
                                context,
                                _FilteredNestExperimentSelection(
                                    selectedExperiment!,
                                    _FilteredNestExperimentAction.remove)),
                        child: Text("Remove")),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"))
                  ],
                );
              });
            });

    if (selection == null) return;

    final experimentToUpdate = selection.experiment;
    experimentToUpdate.nests ??= [];
    Set<String> existingNestIds = experimentToUpdate.nests!.toSet();
    List<String> changedNestIds;
    String successMessage;
    String noChangeMessage;

    if (selection.action == _FilteredNestExperimentAction.add) {
      changedNestIds =
          nestIds.where((nestId) => !existingNestIds.contains(nestId)).toList();
      if (changedNestIds.isNotEmpty) {
        experimentToUpdate.nests = {
          ...experimentToUpdate.nests!,
          ...changedNestIds,
        }.toList();
      }
      successMessage =
          "Added ${changedNestIds.length} filtered nests to ${experimentToUpdate.name}.";
      noChangeMessage =
          "All filtered nests are already in ${experimentToUpdate.name}.";
    } else {
      Set<String> filteredNestIds = nestIds.toSet();
      changedNestIds =
          nestIds.where((nestId) => existingNestIds.contains(nestId)).toList();
      if (changedNestIds.isNotEmpty) {
        experimentToUpdate.nests = experimentToUpdate.nests!
            .where((nestId) => !filteredNestIds.contains(nestId))
            .toList();
      }
      successMessage =
          "Removed ${changedNestIds.length} filtered nests from ${experimentToUpdate.name}.";
      noChangeMessage =
          "None of the filtered nests are in ${experimentToUpdate.name}.";
    }

    if (changedNestIds.isEmpty) {
      await _showFilteredExperimentResult(
          context, "Experiment unchanged", noChangeMessage);
      return;
    }

    final result = await experimentToUpdate.save(widget.firestore);
    if (!mounted) return;
    await _showFilteredExperimentResult(
        context,
        result.success ? "Experiment updated" : "Update failed",
        result.success ? successMessage : result.message);
  }

  Future<void> _showFilteredExperimentResult(
      BuildContext context, String title, String message) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text(title),
              content: Text(message),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.pop(context), child: Text("OK"))
              ],
            ));
  }

  void openFilterDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setDialogState) {
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
                Row(
                  children: [
                    Checkbox(
                      key: Key("livingEggsFilter"),
                      value: _onlyLivingEggs,
                      onChanged: (bool? value) {
                        setState(() {
                          _onlyLivingEggs = value ?? false;
                          if (_onlyLivingEggs) {
                            _clearNestItemFilterCache();
                          }
                        });
                        setDialogState(() {});
                      },
                    ),
                    Expanded(child: Text("Only nests with living eggs")),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      key: Key("eggCountFilter"),
                      value: _filterByEggCount,
                      onChanged: (bool? value) {
                        setState(() {
                          _filterByEggCount = value ?? false;
                          if (_filterByEggCount) {
                            _clearNestItemFilterCache();
                          }
                        });
                        setDialogState(() {});
                      },
                    ),
                    Expanded(child: Text("Filter by egg count")),
                  ],
                ),
                if (_filterByEggCount)
                  MinMaxInput(
                      label: "Egg count",
                      minFun: updateMinEggCount,
                      maxFun: updateMaxEggCount,
                      min: _minEggs?.toDouble(),
                      max: _maxEggs?.toDouble()),
                Row(
                  children: [
                    Checkbox(
                      key: Key("chickCountFilter"),
                      value: _filterByChickCount,
                      onChanged: (bool? value) {
                        setState(() {
                          _filterByChickCount = value ?? false;
                          if (_filterByChickCount) {
                            _clearNestItemFilterCache();
                          }
                        });
                        setDialogState(() {});
                      },
                    ),
                    Expanded(child: Text("Filter by chick count")),
                  ],
                ),
                if (_filterByChickCount)
                  MinMaxInput(
                      label: "Chick count",
                      minFun: updateMinChickCount,
                      maxFun: updateMaxChickCount,
                      min: _minChicks?.toDouble(),
                      max: _maxChicks?.toDouble()),
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
        });
  }

  String _copyableIdsText(List<String> ids) {
    final sortedIds = ids.toSet().toList()..sort();
    return sortedIds.join("\n");
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

  updateMinEggCount(String value) {
    setState(() {
      _minEggs = int.tryParse(value);
    });
  }

  updateMaxEggCount(String value) {
    setState(() {
      _maxEggs = int.tryParse(value);
    });
  }

  updateMinChickCount(String value) {
    setState(() {
      _minChicks = int.tryParse(value);
    });
  }

  updateMaxChickCount(String value) {
    setState(() {
      _maxChicks = int.tryParse(value);
    });
  }

  updateYearFilter(int value) {
    collectionName = yearToNestCollectionName(value);
    _clearNestItemFilterCache();
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
      _minChicks = null;
      _maxChicks = null;
      _minLocationAccuracy = null;
      _maxLocationAccuracy = null;
      _onlyLivingEggs = false;
      _filterByEggCount = false;
      _filterByChickCount = false;
      _clearNestItemFilterCache();
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
    if (_minEggAge == null && _maxEggAge == null && e.first_egg == null)
      return true;
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
    if (_minLocationAccuracy == null && _maxLocationAccuracy == null)
      return true;
    if (_minLocationAccuracy == null)
      return e.getAccuracy() < _maxLocationAccuracy!;
    if (_maxLocationAccuracy == null)
      return e.getAccuracy() > _minLocationAccuracy!;
    return e.getAccuracy() > _minLocationAccuracy! &&
        e.getAccuracy() < _maxLocationAccuracy!;
  }

  Future<List<Egg>> _nestItems(Nest nest) {
    String cacheKey = _nestItemsCacheKey(nest);
    if (_nestItemsCache.containsKey(cacheKey)) {
      return Future.value(_nestItemsCache[cacheKey]!);
    }

    return _nestItemsFutures.putIfAbsent(cacheKey, () async {
      try {
        List<Egg> nestItems = await nest.eggs(widget.firestore);
        _nestItemsCache[cacheKey] = nestItems;
        return nestItems;
      } finally {
        _nestItemsFutures.remove(cacheKey);
      }
    });
  }

  bool _countMatches(bool enabled, int count, int? min, int? max) {
    if (!enabled) return true;
    if (min == null && max == null) return count > 0;
    if (min != null && count < min) return false;
    if (max != null && count > max) return false;
    return true;
  }

  bool _matchesNestItemFilters(List<Egg> nestItems) {
    if (_onlyLivingEggs &&
        !nestItems.any((egg) => egg.type() == 'egg' && egg.status.canMeasure)) {
      return false;
    }

    int eggCount = nestItems.where((egg) => egg.type() == 'egg').length;
    if (!_countMatches(_filterByEggCount, eggCount, _minEggs, _maxEggs)) {
      return false;
    }

    int chickCount = nestItems.where(_isChickItem).length;
    if (!_countMatches(
        _filterByChickCount, chickCount, _minChicks, _maxChicks)) {
      return false;
    }

    return true;
  }

  bool _isChickItem(Egg egg) {
    return egg.type() == 'chick' || egg.status.hasHatched();
  }

  Future<bool> filterByNestItems(Nest nest) async {
    if (!_usesNestItemFilters) return true;
    return _matchesNestItemFilters(await _nestItems(nest));
  }

  List<Nest> _getBaseFilteredItems(List<FirestoreItem> items) {
    List<Nest> nests = items.map((e) => e as Nest).toList();

    nests = nests.where(filterByText).toList();
    nests = nests.where(filterByExperiments).toList();
    nests = nests.where(filterBySpecies).toList();
    nests = nests.where(filterByNestAge).toList();
    nests = nests.where(filterByFirstEggAge).toList();
    nests = nests.where(filterByLocationAccuracy).toList();
    return nests;
  }

  Future<List<Nest>> getFilteredItemsAsync(List<FirestoreItem> items) async {
    List<Nest> nests = _getBaseFilteredItems(items);
    if (!_usesNestItemFilters) return nests;

    List<Nest?> filteredNests = await Future.wait(nests.map((nest) async {
      if (await filterByNestItems(nest)) {
        return nest;
      }
      return null;
    }));

    return filteredNests.whereType<Nest>().toList();
  }

  @override
  List<Nest> getFilteredItems(List<FirestoreItem> items) {
    List<Nest> nests = _getBaseFilteredItems(items);
    if (!_usesNestItemFilters) return nests;

    return nests.where((nest) {
      List<Egg>? nestItems = _nestItemsCache[_nestItemsCacheKey(nest)];
      return nestItems != null && _matchesNestItemFilters(nestItems);
    }).toList();
  }

  Widget _buildNestListView(
      BuildContext context, List<Nest> nests, bool disabled) {
    return ListView.builder(
        itemCount: nests.length,
        itemBuilder: (context, index) {
          return Material(
              color: Colors.transparent,
              child: nests[index].getListTile(context, widget.firestore,
                  disabled: disabled, groups: sps?.markerColorGroups ?? []));
        });
  }

  @override
  Widget listAllItems(BuildContext context, List<FirestoreItem> inputItems) {
    final appYear = sps?.selectedYear ?? DateTime.now().year;
    bool disabled = selectedYear != appYear && !(sps?.isAdmin ?? false);
    List<Nest> nests = _getBaseFilteredItems(inputItems);

    if (!_usesNestItemFilters) {
      return _buildNestListView(context, nests, disabled);
    }

    return FutureBuilder<List<Nest>>(
        future: getFilteredItemsAsync(inputItems),
        builder: (context, AsyncSnapshot<List<Nest>> snapshot) {
          if (snapshot.hasError) {
            return Container(
                padding: EdgeInsets.all(40.0),
                child: Text("Error loading items"));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return _buildNestListView(context, snapshot.data!, disabled);
        });
  }

  @override
  Future<void> executeDownload() async {
    List<Nest> filteredItems =
        await getFilteredItemsAsync(fsService?.items ?? []);
    await exportToExcel(filteredItems, "nests");
  }

  @override
  Future<List<FirestoreItem>> loadAllItemsForSelectedYear() async {
    final snapshot = await widget.firestore
        .collection(yearToNestCollectionName(selectedYear))
        .get();
    final allNests = snapshot.docs
        .map((document) => Nest.fromDocSnapshot(document))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return allNests;
  }
}
