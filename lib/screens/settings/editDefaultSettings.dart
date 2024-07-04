

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/modifingButtons.dart';
import 'package:flutter_bird_colony/models/firestore/defaultSettings.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/measure.dart';
import 'package:flutter_bird_colony/screens/listMeasures.dart';
import 'package:flutter_bird_colony/screens/settings/listMarkerColorGroups.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

class EditDefaultSettings extends StatefulWidget {
  final FirebaseFirestore firestore;
  const EditDefaultSettings({Key? key, required this.firestore})  : super(key: key);

@override
State<EditDefaultSettings> createState() => _EditDefaultSettingsState();
}



class _EditDefaultSettingsState extends State<EditDefaultSettings> {
    SharedPreferencesService? sps;
    String type = "default";
    DefaultSettings defaultSettings = DefaultSettings(
      desiredAccuracy: 4,
      selectedYear: DateTime.now().year,
      autoNextBand: false,
      autoNextBandParent: false,
      defaultLocation: GeoPoint(58.766218, 23.430432),
    defaultCameraZoom: 16.35,
    defaultCameraBearing: 270,
    biasedRepeatedMeasurements: false,
    measures: [Measure.note()],
    markerColorGroups: [],
    defaultSpecies: Species(english: "", latinCode: "", local: ""),
    );

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sps = Provider.of<SharedPreferencesService>(context, listen: false);
      type = sps!.settingsType;
      widget.firestore.collection('settings').doc(type).get().then((value) {
        if (value.exists) {
              defaultSettings = DefaultSettings.fromDocSnapshot(value);
          setState(() {});
        }
      });
      setState(() {});
    });
    }

    @override
    dispose(){
      super.dispose();
    }

  updateLocalSettings() {
    sps!.setFromDefaultSettings(defaultSettings);
    //refresh settings
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, "/settings");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: (sps?.showAppBar ?? true)
            ? AppBar(
                title: Text('Edit Default Settings'),
              )
            : null,
        body: SafeArea(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                    child: Column(children: [
    ...defaultSettings.getDefaultSettingsForm(context, setState, sps),
              ListMeasures(
                  measures: defaultSettings.measures,
                  onMeasuresUpdated: (measures) {
                    setState(() {
        defaultSettings.measures = measures;
      });
    }),
              SizedBox(height: 10),
              ListMarkerColorGroups(
                  markers: defaultSettings.markerColorGroups,
                  onMarkersUpdated: (markers) {
                    setState(() {
                      defaultSettings.markerColorGroups = markers;
                    });
                  }),
              SizedBox(height: 30),
              ModifyingButtons(
                  firestore: widget.firestore,
                  context: context,
                  setState: setState,
                  getItem: () => defaultSettings,
                  type: type,
                  otherItems: null,
                  onSaveOK: updateLocalSettings)
                ])))));
  }
}