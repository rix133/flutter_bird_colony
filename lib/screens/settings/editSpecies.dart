

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/modifingButtons.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

class EditSpecies extends StatefulWidget {
  final FirebaseFirestore firestore;
  const EditSpecies({Key? key, required this.firestore})  : super(key: key);


@override
State<EditSpecies> createState() => _EditSpeciesState();
}



class _EditSpeciesState extends State<EditSpecies> {
    SharedPreferencesService? sps;
    Species species = Species(english: '', local: '', latinCode: '');
    String type = "default";

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sps = Provider.of<SharedPreferencesService>(context, listen: false);
      type = sps!.settingsType;
      species.responsible = sps!.userName;
        var map = ModalRoute.of(context)?.settings.arguments;
        if (map != null) {
            species = map as Species;
      }
      setState(() {});
    });
    }

    @override
    dispose(){
      super.dispose();
    }

    Species getSpecies() {
      species.responsible = sps?.userName ?? species.responsible;
      return species;
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: (sps?.showAppBar ?? true)
            ? AppBar(
                title: Text('Edit Species'),
              )
            : null,
        body: SafeArea(
            child: Container(
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                    child: Column(children: [
    ...species.getSpeciesForm(context, setState),
    SizedBox(height: 20),
          ModifyingButtons(firestore: widget.firestore, context:context, setState:setState, getItem: getSpecies, type:type, otherItems: null)
                ])))));
  }
}