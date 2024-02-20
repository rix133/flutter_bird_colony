

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/modifingButtons.dart';
import 'package:kakrarahu/models/defaultSettings.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/models/species.dart';
import 'package:provider/provider.dart';

class EditDefaultSettings extends StatefulWidget {
const EditDefaultSettings({Key? key}) : super(key: key);

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
          FirebaseFirestore.instance.collection('settings').doc(type).get().then((value) {
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
    SizedBox(height: 30),
    modifingButtons(context, setState, (context) => defaultSettings, type, null)
          ]))));
  }
}