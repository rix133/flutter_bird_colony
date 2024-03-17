import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/design/minMaxInput.dart';
import 'package:kakrarahu/design/speciesRawAutocomplete.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';

import 'firestore/species.dart';

class MarkerColorGroup {
  double color;
  int minAge;
  int maxAge;
  int parents;
  String species;
  String name;

  Color getColor() {
    return HSVColor.fromAHSV(1, color, 1, 1).toColor();
  }

  setColor(Color color) {
    this.color = HSVColor.fromColor(color).hue;
  }

  LocalSpeciesList speciesList = LocalSpeciesList();
  Species selectedSpecies = Species.empty();

  MarkerColorGroup(
      {required this.color,
      required this.minAge,
      required this.maxAge,
      required this.parents,
      required this.species,
      required this.name});

  MarkerColorGroup.magenta(species)
      : this(
            color: BitmapDescriptor.hueMagenta,
            minAge: 10,
            maxAge: 36,
            parents: 2,
            species: species,
            name: "parent trapping");

  MarkerColorGroup.fromJson(Map<String, dynamic> json)
      : color = json['color'],
        minAge = json['minAge'],
        maxAge = json['maxAge'],
        parents = json['parents'],
        species = json['species'],
        name = json['name'];

  Map<String, dynamic> toJson() => {
        'color': color,
        'minAge': minAge,
        'maxAge': maxAge,
        'parents': parents,
        'species': species,
        'name': name
      };

  Widget getForm(
      BuildContext context, Function setState, SharedPreferencesService? sps) {
    speciesList = sps?.speciesList ?? LocalSpeciesList();
    selectedSpecies = speciesList.getSpecies(species);
    return (SingleChildScrollView(
        child: Column(children: [
      SizedBox(height: 10),
      TextFormField(
        initialValue: name,
        decoration: InputDecoration(labelText: 'Name'),
        onChanged: (value) {
          name = value;
          setState();
        },
      ),
      SizedBox(height: 10),
      SpeciesRawAutocomplete(
          returnFun: (Species s) {
            species = s.english;
            setState(() {});
          },
          species: selectedSpecies,
          speciesList: sps?.speciesList ?? LocalSpeciesList(),
          borderColor: Colors.white38,
          bgColor: Colors.amberAccent,
          labelTxt: 'Species',
          labelColor: Colors.grey),
      SizedBox(height: 10),
      Text('Nest first egg age'),
      SizedBox(height: 5),
      MinMaxInput(
          label: "Days",
          minFun: (v) => minAge = int.parse(v),
          maxFun: (v) => maxAge = int.parse(v),
          min: minAge.toDouble(),
          max: maxAge.toDouble()),
      SizedBox(height: 10),
      TextFormField(
        initialValue: parents.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Parents per nest',
          hintText: '2',
        ),
        onChanged: (value) {
          parents = int.parse(value);
          setState();
        },
      ),
      SizedBox(height: 10),
      ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.black87,
                title: const Text('Pick a color!'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: getColor(),
                    enableAlpha: false,
                    paletteType: PaletteType.hsv,
                    labelTypes: [ColorLabelType.hsv],
                    onColorChanged: (Color v) => setColor(v),
                    pickerAreaHeightPercent: 0.8,
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    child: const Text('Got it'),
                    onPressed: () {
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Padding(
            child: Text("Pick color"),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(getColor()),
        ),
      ),
    ])));
  }

  ListTile getListTile(
      BuildContext context, onSaved, onRemoved, SharedPreferencesService? sps) {
    return ListTile(
      title: Text(name.isEmpty ? "undefined" : species + " " + name),
      subtitle: Text("First egg age: " +
          minAge.toString() +
          "-" +
          maxAge.toString() +
          " days"),
      trailing: ElevatedButton.icon(
        onPressed: () => showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.black87,
                content: StatefulBuilder(
                  // Add this
                  builder:
                      (BuildContext context, StateSetter alertDialogSetState) {
                    return getForm(context, alertDialogSetState,
                        sps); // Pass alertDialogSetState here
                  },
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      onRemoved(this);
                      Navigator.pop(context);
                    },
                    child: Text('Remove'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onSaved(this);
                      Navigator.pop(context);
                    },
                    child: Text('Save'),
                  ),
                ],
              );
            }),
        icon: Icon(Icons.edit, color: Colors.black),
        label: Text("Edit"),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(getColor()),
        ),
      ),
    );
  }
}
