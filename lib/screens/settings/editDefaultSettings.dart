

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:kakrarahu/screens/listMeasures.dart';
import 'package:kakrarahu/models/firestore/defaultSettings.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/models/firestore/species.dart';
import 'package:provider/provider.dart';

import 'package:kakrarahu/models/measure.dart';

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
      biasedRepeatedMeasurements: false,
      settingsType: "default",
      measures: [Measure.note()],
      defaultSpecies: Species(english: "", latinCode: "", local: ""),
    );

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sps = Provider.of<SharedPreferencesService>(context, listen: false);
        var map = ModalRoute.of(context)?.settings.arguments;
        if (map != null) {
          map = map as Map<String, dynamic>;
          if (map["defaultSettings"] != null) {
            defaultSettings = map["defaultSettings"] as DefaultSettings;
            setState(() {  });
          }
        } else {
          widget.firestore.collection('settings').doc(type).get().then((value) {
            if (value.exists) {
              defaultSettings = DefaultSettings.fromDocSnapshot(value);
            }
            setState(() {  });
          });
        }

      });
    }

    @override
    dispose(){
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit default settings'),
      ),
      body: Padding(padding: EdgeInsets.all(16.0),
      child:SingleChildScrollView(child:Column(
        children: [
    ...defaultSettings.getDefaultSettingsForm(context, setState, sps),
    ListMeasures(measures: defaultSettings.measures, onMeasuresUpdated: (measures) {
      setState(() {
        defaultSettings.measures = measures;
      });
    }),
    SizedBox(height: 30),
          ModifyingButtons(firestore: widget.firestore, context: context, setState: setState, getItem: () => defaultSettings, type:type, otherItems: null)
          ]))));
  }
}