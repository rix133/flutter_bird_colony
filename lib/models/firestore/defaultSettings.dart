import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/speciesRawAutocomplete.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/models/markerColorGroup.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DefaultSettings implements FirestoreItem {
  String? id;
  double desiredAccuracy;
  int selectedYear;
  bool autoNextBand;
  bool autoNextBandParent;
  GeoPoint defaultLocation;
  bool biasedRepeatedMeasurements;
  List<Measure> measures = [];
  DateTime? last_modified;
  Species defaultSpecies;
  List<MarkerColorGroup> markerColorGroups = [];

  @override
  String? responsible;

  DefaultSettings(
      {this.id,
      required this.desiredAccuracy,
      required this.selectedYear,
      required this.autoNextBand,
      required this.autoNextBandParent,
      required this.defaultLocation,
      required this.biasedRepeatedMeasurements,
      required this.defaultSpecies,
      required this.measures,
      required this.markerColorGroups,
      this.responsible});

  DefaultSettings copy() {
    return DefaultSettings(
        id: id,
        desiredAccuracy: desiredAccuracy,
        selectedYear: selectedYear,
        autoNextBand: autoNextBand,
        autoNextBandParent: autoNextBandParent,
        defaultLocation: defaultLocation,
        biasedRepeatedMeasurements: biasedRepeatedMeasurements,
        defaultSpecies: defaultSpecies.copy(),
        measures: measures.map((e) => e.copy()).toList(),
        markerColorGroups: markerColorGroups.map((e) => e.copy()).toList(),
        responsible: responsible);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'desiredAccuracy': desiredAccuracy,
      'selectedYear': selectedYear,
      'autoNextBand': autoNextBand,
      'autoNextBandParent': autoNextBandParent,
      'defaultLocation': defaultLocation,
      'biasedRepeatedMeasurements': biasedRepeatedMeasurements,
      'defaultSpecies': defaultSpecies.toJson(),
      'measures': measures.map((e) => e.toFormJson()).toList(),
      'responsible': responsible ?? '',
      'markerColorGroups': markerColorGroups.map((e) => e.toJson()).toList()
    };
  }

  @override
  String get name => id ?? '';

  @override
  DateTime get created_date => last_modified ?? DateTime.now();

  getCameraPosition() {
    return CameraPosition(
      target: LatLng(defaultLocation.latitude, defaultLocation.longitude),
      zoom: 14.4746,
    );
  }

  @override
  factory DefaultSettings.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    Species? defaultSpecies = json['defaultSpecies'] == null
        ? Species(english: '', local: '', latinCode: '')
        : Species.fromJson(json['defaultSpecies']);
    return DefaultSettings(
        id: snapshot.id,
        desiredAccuracy: (json['desiredAccuracy'] as num).toDouble(),
        selectedYear: json['selectedYear'],
        autoNextBand: json['autoNextBand'],
        autoNextBandParent: json['autoNextBandParent'],
        defaultLocation: json['defaultLocation'],
        biasedRepeatedMeasurements: json['biasedRepeatedMeasurements'],
        measures: json['measures'] == null
            ? []
            : (json['measures'] as List<dynamic>)
                .map((e) => Measure.fromFormJson(e))
                .toList(),
        defaultSpecies: defaultSpecies,
        markerColorGroups: json['markerColorGroups'] == null
            ? []
            : (json['markerColorGroups'] as List<dynamic>)
                .map((e) => MarkerColorGroup.fromJson(e))
                .toList(),
        responsible: json['responsible']);
  }

  @override
  Future<UpdateResult> save(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      String type = "default"}) {
    if (id == null) {
      id = type;
    }
    last_modified = DateTime.now();
    return (firestore
        .collection("settings")
        .doc(id)
        .set(toJson())
        .then((value) => UpdateResult.saveOK(item: this))
        .catchError((e) => UpdateResult.error(message: e.toString())));
  }

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool soft = true,
      String type = "default"}) {
    if (id == null) {
      return Future.value(UpdateResult.deleteOK(item: this));
    }
    return (FSItemMixin().deleteFiresoreItem(
        this,
        firestore.collection('settings'),
        firestore
            .collection('settings')
            .doc(type)
            .collection("deletedSettings")));
  }

  @override
  Future<List<DefaultSettings>> changeLog(FirebaseFirestore firestore) async {
    return (firestore
        .collection('settings')
        .doc(id)
        .collection('changeLog')
        .get()
        .then((value) => value.docs
            .map((e) => DefaultSettings.fromDocSnapshot(e))
            .toList()));
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    return [
      TextCellValue('Desired accuracy'),
      TextCellValue('Selected year'),
      TextCellValue('Auto next band'),
      TextCellValue('Auto next band parent'),
      TextCellValue('Default location'),
      TextCellValue('Biased repeated measurements'),
      TextCellValue('Default species'),
      TextCellValue('Responsible'),
    ];
  }

  @override
  Future<List<List<CellValue>>> toExcelRows() {
    return Future.value([
      [
        TextCellValue(desiredAccuracy.toString()),
        TextCellValue(selectedYear.toString()),
        TextCellValue(autoNextBand.toString()),
        TextCellValue(autoNextBandParent.toString()),
        TextCellValue(defaultLocation.toString()),
        TextCellValue(biasedRepeatedMeasurements.toString()),
        TextCellValue(defaultSpecies.toString()),
        TextCellValue(responsible ?? ''),
      ]
    ]);
  }

  List<Widget> getDefaultSettingsForm(
      BuildContext context, Function setState, SharedPreferencesService? sps) {
    return ([
      SizedBox(height: 10),
      SpeciesRawAutocomplete(
          returnFun: (Species s) {
            defaultSpecies = s;
            setState(() {});
          },
          species: defaultSpecies,
          speciesList: sps?.speciesList ?? LocalSpeciesList(),
          borderColor: Colors.white38,
          bgColor: Colors.amberAccent,
          labelTxt: 'Default species',
          labelColor: Colors.grey),
      SizedBox(height: 10),
      TextFormField(
        key: Key('desiredAccuracy'),
        initialValue: desiredAccuracy.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Desired accuracy (m)',
          hintText: '4.0',
        ),
        onChanged: (value) {
          desiredAccuracy = double.parse(value);
          setState(() {});
        },
      ),
      SizedBox(height: 10),
      Text('Selected year $selectedYear'),
      Slider(
        value: selectedYear.toDouble(),
        onChanged: (double value) {
          setState(() {
            selectedYear = value.toInt();
          });
        },
        min: DateTime.now().year.toDouble() - 2,
        max: DateTime.now().year.toDouble() + 2,
        divisions: 5,
        label: selectedYear.toString(),
      ),
      SizedBox(height: 10),
      SwitchListTile(
        title: const Text('Auto next band chick'),
        value: autoNextBand,
        onChanged: (bool value) {
          autoNextBand = value;
          setState(() {});
        },
      ),
      SizedBox(height: 10),
      SwitchListTile(
        title: const Text('Auto next band parent'),
        value: autoNextBandParent,
        onChanged: (bool value) {
          autoNextBandParent = value;
          setState(() {});
        },
      ),
      SizedBox(height: 10),
      TextFormField(
        initialValue: defaultLocation.latitude.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Default location latitude',
          hintText: 'Default location latitude',
        ),
        onChanged: (value) {
          defaultLocation =
              GeoPoint(double.parse(value), defaultLocation.longitude);
          setState(() {});
        },
      ),
      SizedBox(height: 10),
      TextFormField(
        initialValue: defaultLocation.longitude.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Default location longitude',
          hintText: 'Default location longitude',
        ),
        onChanged: (value) {
          defaultLocation =
              GeoPoint(defaultLocation.latitude, double.parse(value));
          setState(() {});
        },
      ),
      SizedBox(height: 10),
      SwitchListTile(
        title: const Text('Observer bias repeated measures'),
        value: biasedRepeatedMeasurements,
        onChanged: (bool value) {
          biasedRepeatedMeasurements = value;
          setState(() {});
        },
      ),
    ]);
  }

  List<UpdateResult> validate(SharedPreferencesService? sps,
      {List<FirestoreItem> otherItems = const []}) {
    return [];
  }

  @override
  Widget getListTile(BuildContext context, FirebaseFirestore firestore,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    throw UnimplementedError();
  }
}
