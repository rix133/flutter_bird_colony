import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import '../../design/listScreenWidget.dart';
import '../../models/firestore/firestoreItem.dart';
import '../../services/speciesService.dart';

class ListSpecies extends ListScreenWidget<Species> {
  const ListSpecies({Key? key, required FirebaseFirestore firestore})  : super(key: key, title: 'species', icon: Icons.nat_rounded, firestore: firestore);

  @override
  ListScreenWidgetState<Species> createState() => _ListSpeciesState();
}

class _ListSpeciesState extends ListScreenWidgetState<Species> {

  List<Species> species = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      collectionName = sps?.settingsType ?? "default";
      fsService = Provider.of<SpeciesService>(context, listen: false);
      stream = fsService?.watchItems(collectionName) ?? Stream.empty();

      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/editSpecies');
          },
          icon: Icon(Icons.add),
          label: Padding(
              child: Text("Add Species", style: TextStyle(fontSize: 18)),
              padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey))),
    );
  }

  @override
  Future<void> executeDownload() {
    return (FSItemMixin().downloadExcel(species, "species", widget.firestore));
  }

  @override
  bool filterByText(Species item) {
    if(searchController.text.isEmpty) return true;
    return ((item.latin ?? "").toLowerCase().contains(searchController.text.toLowerCase()) ||
        item.english.toLowerCase().contains(searchController.text.toLowerCase()) ||
        item.local.toLowerCase().contains(searchController.text.toLowerCase())
    );
  }



  @override
  void openFilterDialog(BuildContext context) {
    //show alert dialog that this has no effect
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text("Filter"),
            content: Text("This list has no filter options"),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Close", style: TextStyle(color: Colors.red))),
            ],
          );
        });
  }

  @override
  updateYearFilter(int value) {
    return true;
  }

  List<Species> getFilteredItems(List<FirestoreItem> items) {
    species = items.map((e) => e as Species).toList();
    species = species.where(filterByText).toList();
    return species;
  }


}
