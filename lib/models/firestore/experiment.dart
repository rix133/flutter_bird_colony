import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/experimentedItem.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:flutter_bird_colony/design/filledIconButton.dart';
import 'package:flutter_bird_colony/design/changelogRestoreDialog.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/sharedPreferencesService.dart';
import '../markerColorGroup.dart';
import 'bird.dart';
import 'nest.dart';

enum _NestQuickAction { markChecked, uncheck, complete, clearCompleted }

class Experiment implements FirestoreItem {
  String? id;
  String name = "New Experiment";
  String? description;
  String? responsible;
  Color color = Colors.grey;
  int? year = DateTime.now().year;
  List<String>? nests = [];
  List<String>? birds = [];
  List<Measure> measures = [];
  String type = "nest";
  DateTime? last_modified;
  DateTime? created = DateTime.now();

  List<String> previousNests = [];
  List<String> previousBirds = [];
  Map<String, dynamic> _previousSimpleJson = {};
  final Map<String, Nest> _loadedNestItems = {};
  final Set<String> _missingNestItems = {};
  int? _loadedNestYear;

  Experiment copy() {
    return Experiment(
        id: id,
        name: name,
        description: description,
        responsible: responsible,
        year: year,
        nests: List.from(nests ?? []),
        birds: List.from(birds ?? []),
        type: type,
        measures: List.from(measures.map((m) => m.copy())),
        color: color,
        last_modified: last_modified,
        created: created);
  }

  Experiment(
      {this.id,
      required this.name,
      this.description,
      this.responsible,
      this.year,
      this.nests,
      this.type = "nest",
      this.measures = const [],
      this.birds,
      this.color = Colors.blue,
      this.last_modified,
      this.created});

  @override
  DateTime get created_date => created ?? DateTime(1900);

  Experiment.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    id = snapshot.id;
    name = json['name'] ?? "Untitled experiment";
    description = json['description'];
    responsible = json['responsible'];
    year = json['year'];
    measures = (json['measures'] as List<dynamic>?)
            ?.map((e) => Measure.fromJson(e))
            .toList() ??
        [];
    nests = List<String>.from(json['nests'] ?? []);
    birds = List<String>.from(json['birds'] ?? []);
    type = json['type'] ?? "nest";
    color = Color(int.parse(json['color']));
    last_modified = (json['last_modified'] as Timestamp).toDate();
    created = (json['created'] as Timestamp).toDate();
    previousBirds = List.from(birds ?? []);
    previousNests = List.from(nests ?? []);
    _previousSimpleJson = Map<String, dynamic>.from(toSimpleJson());
  }

  Map<String, dynamic> toSimpleJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32().toString(),
      'measures': measures.map((e) => e.toFormJson()).toList()
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'responsible': responsible,
      'year': year,
      'nests': nests,
      'birds': birds,
      'type': type,
      'color': color.toARGB32().toString(),
      'last_modified': last_modified,
      'measures': measures.map((e) => e.toJson()).toList(),
      'created': created
    };
  }

  bool hasNests() {
    if (nests != null) {
      if (nests!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool hasBirds() {
    if (birds != null) {
      if (birds!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _isAdmin(BuildContext context) {
    try {
      return Provider.of<SharedPreferencesService>(context, listen: false)
          .isAdmin;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, Nest>> _loadExperimentNests(
      FirebaseFirestore firestore) async {
    if (!hasNests()) {
      _loadedNestItems.clear();
      _missingNestItems.clear();
      return {};
    }

    final currentYear = year ?? DateTime.now().year;
    if (_loadedNestYear != currentYear) {
      _loadedNestItems.clear();
      _missingNestItems.clear();
      _loadedNestYear = currentYear;
    }

    final currentIds = nests!.toSet();
    _loadedNestItems.removeWhere((id, _) => !currentIds.contains(id));
    _missingNestItems.removeWhere((id) => !currentIds.contains(id));

    final idsToLoad = currentIds
        .where((nestId) =>
            !_loadedNestItems.containsKey(nestId) &&
            !_missingNestItems.contains(nestId))
        .toList();

    if (idsToLoad.isNotEmpty) {
      final nestCollection =
          firestore.collection(yearToNestCollectionName(currentYear));
      final snapshots = await Future.wait(
          idsToLoad.map((nestId) => nestCollection.doc(nestId).get()));

      for (final snapshot in snapshots) {
        if (snapshot.exists) {
          _loadedNestItems[snapshot.id] = Nest.fromDocSnapshot(snapshot);
        } else {
          _missingNestItems.add(snapshot.id);
        }
      }
    }

    return Map<String, Nest>.unmodifiable(_loadedNestItems);
  }

  Widget _removeNestButton(String nestId, Function setState) {
    return FilledIconButton(
      key: Key("removeNestFromExperiment_$nestId"),
      icon: Icons.close,
      iconColor: Colors.white,
      backgroundColor: Colors.redAccent,
      onPressed: () {
        setState(() {
          nests!.remove(nestId);
        });
      },
    );
  }

  Widget _nestRowActions(BuildContext context, FirebaseFirestore firestore,
      Nest nest, String nestId, Function setState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: "Nest quick actions",
          child: FilledIconButton(
            key: Key("experimentNestQuickActions_$nestId"),
            icon: Icons.more_vert,
            iconColor: Colors.black,
            backgroundColor: Colors.orangeAccent,
            onPressed: () => _handleNestQuickAction(
                context, firestore, nest, nestId, setState),
          ),
        ),
        SizedBox(width: 8),
        _removeNestButton(nestId, setState),
      ],
    );
  }

  Widget _nestItemsList(BuildContext context, FirebaseFirestore firestore,
      Function setState, List<MarkerColorGroup> groups) {
    return FutureBuilder<Map<String, Nest>>(
        future: _loadExperimentNests(firestore),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error loading nests");
          }

          if (!snapshot.hasData) {
            return Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator());
          }

          final nestMap = snapshot.data ?? {};
          return Column(
              children: (nests ?? []).map((nestId) {
            final nest = nestMap[nestId];
            if (nest == null) {
              return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text('Nest ID: $nestId'),
                        subtitle: Text("Nest not found"),
                        trailing: _removeNestButton(nestId, setState),
                      )));
            }

            return Padding(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                child: Material(
                    color: Colors.transparent,
                    child: nest.getListTile(context, firestore,
                        groups: groups,
                        mapActionOverride: _nestRowActions(
                            context, firestore, nest, nestId, setState))));
          }).toList());
        });
  }

  Future<UpdateResult> setExperimentNestCheckedForToday(
      FirebaseFirestore firestore, String nestId,
      {required bool checked, DateTime? checkedAt}) async {
    if (nestId.isEmpty) {
      return UpdateResult.error(message: "Nest ID is empty");
    }

    final effectiveCheckedAt = checkedAt ?? DateTime.now();
    final nestCollection = firestore
        .collection(yearToNestCollectionName(year ?? DateTime.now().year));

    try {
      await nestCollection.doc(nestId).update(checked
          ? {
              'bulk_checked': effectiveCheckedAt,
              'bulk_checked_dates': FieldValue.arrayUnion([effectiveCheckedAt])
            }
          : {'bulk_checked': FieldValue.delete()});
    } catch (error) {
      return UpdateResult.error(message: error.toString());
    }

    return UpdateResult.saveOK(item: this)
      ..message = checked
          ? "Marked nest $nestId checked today"
          : "Unchecked nest $nestId for today";
  }

  Future<UpdateResult> setExperimentNestCompleted(
      FirebaseFirestore firestore, String nestId,
      {required bool completed}) async {
    if (nestId.isEmpty) {
      return UpdateResult.error(message: "Nest ID is empty");
    }

    final nestCollection = firestore
        .collection(yearToNestCollectionName(year ?? DateTime.now().year));

    try {
      await nestCollection.doc(nestId).update({'completed': completed});
    } catch (error) {
      return UpdateResult.error(message: error.toString());
    }

    return UpdateResult.saveOK(item: this)
      ..message = completed
          ? "Marked nest $nestId completed"
          : "Cleared completed for nest $nestId";
  }

  Future<_NestQuickAction?> _showNestQuickActionsDialog(
      BuildContext context, Nest nest, String nestId) {
    Widget actionButton({
      required Key key,
      required IconData icon,
      required String label,
      required Color color,
      required _NestQuickAction action,
    }) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: key,
          icon: Icon(icon),
          label: Text(label),
          onPressed: () => Navigator.pop(context, action),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(color),
            foregroundColor: WidgetStateProperty.all(Colors.black87),
          ),
        ),
      );
    }

    return showDialog<_NestQuickAction>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text("Nest $nestId actions"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "Checked: ${nest.checkedStr().isEmpty ? "not today" : nest.checkedStr()}"),
            Text("Completed: ${nest.completed ?? false}"),
            SizedBox(height: 12),
            actionButton(
              key: Key("quickMarkNestChecked_$nestId"),
              icon: Icons.check_circle,
              label: "Mark checked today",
              color: Colors.greenAccent,
              action: _NestQuickAction.markChecked,
            ),
            actionButton(
              key: Key("quickUncheckNest_$nestId"),
              icon: Icons.undo,
              label: "Uncheck today",
              color: Colors.orangeAccent,
              action: _NestQuickAction.uncheck,
            ),
            actionButton(
              key: Key("quickCompleteNest_$nestId"),
              icon: Icons.done_all,
              label: "Mark completed",
              color: Colors.lightBlueAccent,
              action: _NestQuickAction.complete,
            ),
            actionButton(
              key: Key("quickClearCompletedNest_$nestId"),
              icon: Icons.remove_done,
              label: "Clear completed",
              color: Colors.grey,
              action: _NestQuickAction.clearCompleted,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNestQuickAction(
      BuildContext context,
      FirebaseFirestore firestore,
      Nest nest,
      String nestId,
      Function setState) async {
    final action = await _showNestQuickActionsDialog(context, nest, nestId);
    if (action == null || !context.mounted) {
      return;
    }

    UpdateResult result;
    DateTime? checkedAt;
    switch (action) {
      case _NestQuickAction.markChecked:
        checkedAt = DateTime.now();
        result = await setExperimentNestCheckedForToday(firestore, nestId,
            checked: true, checkedAt: checkedAt);
        break;
      case _NestQuickAction.uncheck:
        result = await setExperimentNestCheckedForToday(firestore, nestId,
            checked: false);
        break;
      case _NestQuickAction.complete:
        result = await setExperimentNestCompleted(firestore, nestId,
            completed: true);
        break;
      case _NestQuickAction.clearCompleted:
        result = await setExperimentNestCompleted(firestore, nestId,
            completed: false);
        break;
    }

    if (!context.mounted) {
      return;
    }

    if (result.success) {
      setState(() {
        switch (action) {
          case _NestQuickAction.markChecked:
            nest.bulk_checked = checkedAt;
            nest.bulk_checked_dates = [...nest.bulk_checked_dates, checkedAt!];
            break;
          case _NestQuickAction.uncheck:
            nest.bulk_checked = null;
            break;
          case _NestQuickAction.complete:
            nest.completed = true;
            break;
          case _NestQuickAction.clearCompleted:
            nest.completed = false;
            break;
        }
        _loadedNestItems[nestId] = nest;
      });
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(result.success
            ? result.message
            : "Update failed: ${result.message}"),
      ));
  }

  Widget getItemsList(
      BuildContext context, FirebaseFirestore firestore, Function setState,
      {List<MarkerColorGroup> groups = const []}) {
    List<Widget> items = [];
    if (hasNests()) {
      items.add(_copyableIdsButton(context, "nest", nests ?? const <String>[],
          Key("copyExperimentNestIdsButton")));
      items.add(_nestItemsList(context, firestore, setState, groups));
    }
    if (hasBirds()) {
      items.add(_copyableIdsButton(context, "bird", birds ?? const <String>[],
          Key("copyExperimentBirdIdsButton")));
      items.addAll(birds
              ?.map((e) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  child: Material(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(5),
                      child: ListTile(
                        title: Text('Bird ID: $e'),
                        onTap: gotoBird(e, context),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.redAccent),
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(Colors.white60),
                          ),
                          onPressed: () {
                            setState(() {
                              birds!.remove(e);
                            });
                          },
                        ),
                      ))))
              .toList() ??
          []);
    }
    return Column(
      children: items,
    );
  }

  Widget _copyableIdsButton(
      BuildContext context, String itemType, List<String> ids, Key key) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text("${ids.length} ${itemType}s"),
          SizedBox(width: 10),
          ElevatedButton.icon(
            key: key,
            icon: Icon(Icons.copy),
            label: Text("Copy ${itemType} IDs"),
            onPressed: () => _showCopyableIdsDialog(context, itemType, ids),
          ),
        ],
      ),
    );
  }

  Future<void> _showCopyableIdsDialog(
      BuildContext context, String itemType, List<String> ids) async {
    final idsText = _copyableIdsText(ids);
    await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text("${ids.length} ${itemType}s"),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: SingleChildScrollView(
                    child:
                        SelectableText(idsText.isEmpty ? "No IDs" : idsText)),
              ),
              actions: [
                ElevatedButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: idsText)),
                    child: Text("Copy IDs")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"))
              ],
            ));
  }

  String _copyableIdsText(List<String> ids) {
    final sortedIds = ids.toSet().toList()..sort();
    return sortedIds.join("\n");
  }

  @override
  Future<List<Experiment>> changeLog(FirebaseFirestore firestore) async {
    return firestore
        .collection('experiments')
        .doc(id)
        .collection('changelog')
        .get()
        .then((value) {
      List<Experiment> experiments =
          value.docs.map((e) => Experiment.fromDocSnapshot(e)).toList();
      experiments.sort((a, b) => b.last_modified!.compareTo(a.last_modified!));
      return experiments;
    });
  }

  gotoNest(String nest, BuildContext context) {
    return () => {
          Navigator.pushNamed(context, '/editNest',
              arguments: {'nest_id': nest, 'year': year})
        };
  }

  List<UpdateResult> validate(SharedPreferencesService? sps,
      {List<FirestoreItem> otherItems = const []}) {
    return [];
  }

  gotoBird(String band, BuildContext context) {
    return () => {
          Navigator.pushNamed(context, "/editBird",
              arguments: {'bird_id': band})
        };
  }

  getDetailsDialog(BuildContext context, FirebaseFirestore firestore) {
    final isAdmin =
        Provider.of<SharedPreferencesService>(context, listen: false).isAdmin;
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text("Experiment Details"),
      content: SelectionArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Name: $name"),
            Text("Description: ${description ?? ""}"),
            Text("Responsible: ${responsible ?? ""}"),
            Text("Year: ${year ?? ""}"),
            Text("Type: $type"),
            Text("Last Modified: ${last_modified?.toIso8601String() ?? ""}"),
            Text("Created: ${created?.toIso8601String() ?? ""}"),
            Text("Nests: ${nests?.join(", ") ?? ""}"),
            Text("Birds: ${birds?.join(", ") ?? ""}"),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("close"),
        ),
        //download changelog Elevated icon button
        ElevatedButton.icon(
          key: Key("downloadChangelog"),
          icon: Icon(Icons.download),
          label: Text("Download changelog"),
          onPressed: () async {
            Navigator.pop(context);
            await FSItemMixin().downloadChangeLog(
                this.changeLog(firestore), "experiment", firestore);
          },
        ),
        if (isAdmin)
          ElevatedButton.icon(
            icon: Icon(Icons.restore),
            label: Text("Restore version"),
            onPressed: () async {
              Navigator.pop(context);
              if (id == null) {
                return;
              }
              await RestoreFromChangelogDialog.show(
                context,
                itemRef: firestore.collection('experiments').doc(id),
                title: "Restore experiment $name",
              );
            },
          ),
      ],
    );
  }

  dispose() {
    measures.forEach((m) {
      m.dispose();
    });
  }

  String get titleString =>
      '$name${description?.isNotEmpty == true ? ' - $description' : ''}';

  String _itemSummary(String label, String countLabel, List<String>? items) {
    if (items == null || items.isEmpty) return "";
    if (items.length > 7) return "$label: ${items.length} $countLabel";
    return "$label: ${items.join(", ")}";
  }

  Future<UpdateResult> setExperimentNestsCheckedForToday(
      FirebaseFirestore firestore,
      {required bool checked}) async {
    final nestIds =
        (nests ?? []).where((nestId) => nestId.isNotEmpty).toSet().toList();
    if (nestIds.isEmpty) {
      return UpdateResult.error(message: "Experiment has no nests");
    }

    final nestCollection = firestore
        .collection(yearToNestCollectionName(year ?? DateTime.now().year));
    int updated = 0;
    final checkedAt = DateTime.now();

    for (final nestId in nestIds) {
      try {
        await nestCollection.doc(nestId).update(checked
            ? {
                'bulk_checked': checkedAt,
                'bulk_checked_dates': FieldValue.arrayUnion([checkedAt])
              }
            : {'bulk_checked': FieldValue.delete()});
        updated++;
      } catch (_) {
        // Ignore stale experiment references so one missing nest does not block
        // the rest of the experiment from being marked.
      }
    }

    if (updated == 0) {
      return UpdateResult.error(message: "No matching nest documents found");
    }

    return UpdateResult.saveOK(item: this)
      ..message = checked
          ? "Marked $updated nests checked today"
          : "Unchecked $updated nests for today";
  }

  Widget getListTile(BuildContext context, FirebaseFirestore firestore,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    final isAdmin = _isAdmin(context);
    String subtitleNests = _itemSummary("Nests", "nests", nests);
    String subtitleBirds = _itemSummary("Birds", "birds", birds);
    String subtitle = [subtitleNests, subtitleBirds]
        .where((element) => element.isNotEmpty)
        .join(" ");
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: ListTile(
        leading: isAdmin && hasNests()
            ? _ExperimentNestCheckedButtons(
                experiment: this, firestore: firestore, disabled: disabled)
            : null,
        title: Text(titleString, style: TextStyle(fontSize: 20)),
        subtitle:
            Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  getDetailsDialog(context, firestore));
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledIconButton(
              icon: Icons.map,
              iconColor: Colors.black87,
              backgroundColor: Colors.grey,
              onPressed: () {
                showNestMap(context);
              },
            ),
            FilledIconButton(
              icon: Icons.edit,
              iconColor: Colors.black,
              backgroundColor: Colors.white60,
              onPressed: () {
                Navigator.pushNamed(context, '/editExperiment',
                    arguments: this);
              },
            ),
          ],
        ),
      ),
    );
  }

  void showNestMap(BuildContext context) {
    Navigator.pushNamed(context, '/mapNests',
        arguments: {'nest_ids': nests, 'year': year});
  }

  Future<UpdateResult> _updateNestCollection(
      FirebaseFirestore firestore, List<String>? items,
      {bool delete = false}) async {
    CollectionReference nestCollection = firestore
        .collection(yearToNestCollectionName(year ?? DateTime.now().year));
    if (items != null) {
      for (String i in items) {
        final doc = nestCollection.doc(i);
        final value = await doc.get();
        if (!value.exists) {
          continue;
        }

        Nest n = Nest.fromDocSnapshot(value);
        n.experiments =
            n.experiments?.where((element) => element.id != id).toList();
        if (!delete) {
          n.experiments?.add(this);
        }
        final updatedExperiments = n.experiments ?? [];
        await doc.update({
          'experiments':
              updatedExperiments.map((e) => e.toSimpleJson()).toList(),
          'experimentIds':
              updatedExperiments.map((e) => e.id).whereType<String>().toList()
        });
      }
    }
    return UpdateResult.saveOK(item: this);
  }

  Future<UpdateResult> _updateBirdsCollection(
      FirebaseFirestore firestore, List<String>? items,
      {bool delete = false}) async {
    CollectionReference birdCollection = firestore.collection("Birds");
    if (items != null) {
      for (String i in items) {
        final doc = birdCollection.doc(i);
        final value = await doc.get();
        if (!value.exists) {
          continue;
        }

        Bird b = Bird.fromDocSnapshot(value);
        b.experiments =
            b.experiments?.where((element) => element.id != id).toList();
        if (!delete) {
          b.experiments?.add(this);
        }
        final updatedExperiments = b.experiments ?? [];
        await doc.update({
          'experiments':
              updatedExperiments.map((e) => e.toSimpleJson()).toList(),
          'experimentIds':
              updatedExperiments.map((e) => e.id).whereType<String>().toList()
        });
      }
    }
    return UpdateResult.saveOK(item: this);
  }

  List<String> _addedItems(List<String> previousItems, List<String> items) {
    final previousSet = previousItems.toSet();
    return items.where((item) => !previousSet.contains(item)).toList();
  }

  List<String> _deletedItems(List<String> previousItems, List<String> items) {
    final itemSet = items.toSet();
    return previousItems.where((item) => !itemSet.contains(item)).toList();
  }

  bool _jsonEquals(Object? first, Object? second) {
    if (first is Map && second is Map) {
      if (first.length != second.length) {
        return false;
      }
      for (final key in first.keys) {
        if (!second.containsKey(key) || !_jsonEquals(first[key], second[key])) {
          return false;
        }
      }
      return true;
    }

    if (first is List && second is List) {
      if (first.length != second.length) {
        return false;
      }
      for (int i = 0; i < first.length; i++) {
        if (!_jsonEquals(first[i], second[i])) {
          return false;
        }
      }
      return true;
    }

    return first == second;
  }

  bool _experimentMarkerChanged() {
    if (_previousSimpleJson.isEmpty) {
      return previousNests.isNotEmpty || previousBirds.isNotEmpty;
    }

    return !_jsonEquals(_previousSimpleJson, toSimpleJson());
  }

  void _rememberSavedState() {
    previousNests = List.from(nests ?? []);
    previousBirds = List.from(birds ?? []);
    _previousSimpleJson = Map<String, dynamic>.from(toSimpleJson());
  }

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      String type = "default"}) {
    CollectionReference expCollection = firestore.collection('experiments');
    _updateNestCollection(firestore, previousNests, delete: true);
    _updateBirdsCollection(firestore, previousBirds, delete: true);

    return FSItemMixin().deleteFirestoreItem(this, expCollection);
  }

  @override
  Future<UpdateResult> save(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      String type = "default"}) {
    CollectionReference expCollection = firestore.collection('experiments');

    last_modified = DateTime.now();
    nests ??= [];
    birds ??= [];
    //remove duplicate nests
    nests = nests!.toSet().toList();
    birds = birds!.toSet().toList();

    final addedNests = _addedItems(previousNests, nests!);
    final addedBirds = _addedItems(previousBirds, birds!);
    final deletedNests = _deletedItems(previousNests, nests!);
    final deletedBirds = _deletedItems(previousBirds, birds!);
    final markerChanged = _experimentMarkerChanged();
    final nestsToUpdate = markerChanged ? nests! : addedNests;
    final birdsToUpdate = markerChanged ? birds! : addedBirds;

    if (id == null) {
      created = DateTime.now();
      id = created!.toIso8601String();
    }

    //save the experiment data to nests or birds
    return _updateNestCollection(firestore, nestsToUpdate, delete: false)
        .then(
            (v) => _updateNestCollection(firestore, deletedNests, delete: true))
        .then((v) =>
            _updateBirdsCollection(firestore, birdsToUpdate, delete: false))
        .then((v) =>
            _updateBirdsCollection(firestore, deletedBirds, delete: true))
        .then((v) => expCollection
                .doc(id)
                .set(toJson())
                .then(
                    (value) => FSItemMixin().saveChangeLog(this, expCollection))
                .then((value) {
              _rememberSavedState();
              return UpdateResult.saveOK(item: this);
            }))
        .catchError(
            (onError) => UpdateResult.error(message: onError.toString()));
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    List<TextCellValue> baseHeader = [
      TextCellValue('experiment_name'),
      TextCellValue('experiment_description'),
      TextCellValue('experiment_responsible'),
      TextCellValue('experiment_year'),
      TextCellValue('experiment_type'),
      TextCellValue('experiment_last_modified'),
      TextCellValue('experiment_created'),
      // Add more headers as per your requirements
    ];
    if (hasNests()) {
      baseHeader.add(TextCellValue('nest'));
    }
    if (hasBirds()) {
      baseHeader.add(TextCellValue('bird'));
    }
    return baseHeader;
  }

  @override
  Future<List<List<CellValue>>> toExcelRows(
      {List<FirestoreItem>? otherItems}) async {
    List<List<CellValue>> rows = [];
    List<CellValue> baseItems = [
      TextCellValue(name),
      TextCellValue(description ?? ""),
      TextCellValue(responsible ?? ""),
      IntCellValue(year ?? 1900),
      TextCellValue(type),
      last_modified != null
          ? DateTimeCellValue.fromDateTime(last_modified!)
          : TextCellValue(""),
      DateCellValue(
          year: created?.year ?? 1900,
          month: created?.month ?? 1,
          day: created?.day ?? 1),
    ];

    if (hasNests()) {
      for (String nest in nests!) {
        List<CellValue> items = List.from(baseItems);
        items.add(TextCellValue(nest));
        rows.add(items);
      }
    }
    if (hasBirds()) {
      for (String bird in birds!) {
        List<CellValue> items = List.from(baseItems);
        items.add(TextCellValue(bird));
        rows.add(items);
      }
    }

    if (!hasNests() && !hasBirds()) {
      rows.add(baseItems);
    }
    return rows;
  }
}

class _ExperimentNestCheckedButtons extends StatefulWidget {
  final Experiment experiment;
  final FirebaseFirestore firestore;
  final bool disabled;

  const _ExperimentNestCheckedButtons(
      {required this.experiment,
      required this.firestore,
      required this.disabled});

  @override
  State<_ExperimentNestCheckedButtons> createState() =>
      _ExperimentNestCheckedButtonsState();
}

class _ExperimentNestCheckedButtonsState
    extends State<_ExperimentNestCheckedButtons> {
  bool _markingChecked = false;
  bool _unchecking = false;

  bool get _busy => _markingChecked || _unchecking;

  Future<bool> _confirmBulkChange(bool checked) async {
    final nestCount = widget.experiment.nests?.toSet().length ?? 0;
    final title =
        checked ? "Mark nests checked today?" : "Uncheck nests today?";
    final action = checked ? "Mark checked" : "Uncheck";
    final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(title),
            content: Text(checked
                ? "This will mark $nestCount nests in ${widget.experiment.name} checked today without changing their real last modified date."
                : "This will clear the bulk checked date for $nestCount nests in ${widget.experiment.name} without changing their real last modified date."),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(action)),
            ],
          );
        });
    return result ?? false;
  }

  Future<void> _bulkChange(bool checked) async {
    final confirmed = await _confirmBulkChange(checked);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      if (checked) {
        _markingChecked = true;
      } else {
        _unchecking = true;
      }
    });

    final result = await widget.experiment
        .setExperimentNestsCheckedForToday(widget.firestore, checked: checked);
    if (!mounted) {
      return;
    }

    setState(() {
      _markingChecked = false;
      _unchecking = false;
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(result.success
            ? result.message
            : "Update failed: ${result.message}"),
      ));
  }

  Widget _progressButton(Color backgroundColor) {
    return Material(
      color: backgroundColor.withAlpha((backgroundColor.a * 0.5).round()),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
    );
  }

  Widget _markButton() {
    const backgroundColor = Colors.greenAccent;
    if (_markingChecked) {
      return _progressButton(backgroundColor);
    }
    return Tooltip(
      message: "Mark experiment nests checked today",
      child: FilledIconButton(
        key: Key("markExperimentNestsChecked_${widget.experiment.id}"),
        icon: Icons.check_circle,
        iconColor: Colors.black87,
        backgroundColor: backgroundColor,
        onPressed: widget.disabled || _busy ? null : () => _bulkChange(true),
      ),
    );
  }

  Widget _uncheckButton() {
    const backgroundColor = Colors.orangeAccent;
    if (_unchecking) {
      return _progressButton(backgroundColor);
    }
    return Tooltip(
      message: "Uncheck experiment nests today",
      child: FilledIconButton(
        key: Key("uncheckExperimentNestsChecked_${widget.experiment.id}"),
        icon: Icons.undo,
        iconColor: Colors.black87,
        backgroundColor: backgroundColor,
        onPressed: widget.disabled || _busy ? null : () => _bulkChange(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _markButton(),
          SizedBox(width: 4),
          _uncheckButton(),
        ],
      ),
    );
  }
}

Experiment experimentFromSimpleJson(Map<String, dynamic> json) {
  Experiment e = Experiment(
      id: json['id'],
      name: json['name'],
      measures: (json['measures'] as List<dynamic>?)
              ?.map((e) => Measure.fromFormJson(e))
              .toList() ??
          [],
      color: Color(int.parse(json['color'])));
  return e;
}

Container listExperiments(ExperimentedItem item,
    {void Function(Experiment)? onRemove, bool showRemoveHint = false}) {
  if (!item.hasExperiments) {
    return Container();
  }

  List<Widget> experimentButtons = item.experiments?.map((e) {
        Widget button = ElevatedButton(
          key: Key("experimentTag_${e.id ?? e.name}"),
          onPressed: () => null,
          onLongPress: onRemove == null ? null : () => onRemove(e),
          child: Text(e.name),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(e.color),
          ),
        );
        return button;
      }).toList() ??
      [];

  Widget row = Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text("Exp. "),
      ...experimentButtons,
      //add experiment button
    ],
  );

  return Container(
    padding: EdgeInsets.all(8.0),
    child: showRemoveHint
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row,
              SizedBox(height: 4),
              Text("(long press experiment to remove)",
                  style: TextStyle(fontSize: 10)),
            ],
          )
        : row,
  );
}
