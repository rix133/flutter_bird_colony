import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/models/species.dart';


import 'design/listScreenWidget.dart';

class ListSpecies extends ListScreenWidget<Species> {
  const ListSpecies({Key? key}) : super(key: key, title: 'species', icon: Icons.nat_rounded);

  @override
  ListScreenWidgetState<Species> createState() => _ListSpeciesState();
}

class _ListSpeciesState extends ListScreenWidgetState<Species> {

  List<Species> species = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      collection = FirebaseFirestore.instance
          .collection('settings')
          .doc(sps?.settingsType)
          .collection("species");
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
    return(FSItemMixin().downloadExcel(species, "species"));
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

  getFilteredItems(AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
    species = snapshot.data!.docs
        .map<Species>((DocumentSnapshot<Object?> e) => Species.fromDocSnapshot(e))
        .toList();
    species = species.where(filterByText).toList();
    return species;
  }


}
