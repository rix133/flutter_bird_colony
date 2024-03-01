import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/species.dart';
import 'design/listScreenWidget.dart';
import 'models/firestoreItemMixin.dart';
import 'design/speciesRawAutocomplete.dart';

class ListBirds extends ListScreenWidget<Bird> {
  const ListBirds({Key? key, required FirebaseFirestore firestore})  : super(key: key, title: 'birds', icon: Icons.nat_sharp, firestore: firestore);

  @override
  ListScreenWidgetState<Bird> createState() => _ListBirdsState();
}

class _ListBirdsState extends ListScreenWidgetState<Bird> {

  String? _selectedSpecies;
  int? _selectedAge;

  List<Bird> birds = [];
  CollectionReference? collection =
      FirebaseFirestore.instance.collection('Birds');




  @override
  void dispose() {
    birds.forEach((element) {
      element.dispose();
    });
    super.dispose();
  }

  getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          onPressed: null,
          icon: Icon(Icons.add),
          label: Padding(child:Text("Add Bird", style: TextStyle(fontSize: 18)), padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey)
          )
      ),
    );
  }



  void openFilterDialog(BuildContext context){
     showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: Text("Filter"),
              content: SingleChildScrollView(child:Column(
                children: [
                yearInput(context),
                  experimentInput(context),
                  SpeciesRawAutocomplete(
                      returnFun: (Species s) {
                        _selectedSpecies = s.english;
                        setState(() {});
                      },
                      species: Species(english: _selectedSpecies?? "", local: '', latinCode: ''),
                      speciesList: sps?.speciesList ?? LocalSpeciesList(),
                      borderColor: Colors.white38,
                      bgColor: Colors.amberAccent,
                      labelColor: Colors.grey),
                 ])),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Close"))
              ],
            );
          });
  }

  bool filterByYear(Bird e) {
    return e.nest_year == selectedYear || e.ringed_date.year == selectedYear;
  }
  updateYearFilter(int value) {
    setState(() {
      selectedYear = value;
    });
  }

  @override
  void clearFilters() {
    super.clearFilters();
    setState(() {
      _selectedSpecies = null;
      _selectedAge = null;
    });
  }

  bool filterByText(Bird e) {
    return e.band.toLowerCase().contains(searchController.text.toLowerCase()) ||
        (e.color_band != null ? e.color_band!.toLowerCase().contains(searchController.text.toLowerCase()) : false);
  }

  bool filterBySpecies(Bird e) {
    if(_selectedSpecies == null) return true;
    return e.species == _selectedSpecies;
  }
  bool filterByAge(Bird e) {
    if(_selectedAge == null) return true;
    return e.ageInYears() == _selectedAge;
  }

  @override
  Future<void> executeDownload() {
    return(FSItemMixin().downloadExcel(birds, "birds"));
  }

  List<Bird> getFilteredItems(AsyncSnapshot snapshot) {
    birds = snapshot.data!.docs.map<Bird>((DocumentSnapshot document) => Bird.fromDocSnapshot(document)).toList();

    birds = birds.where(filterByText).toList();
    birds = birds.where(filterByExperiments).toList();
    birds = birds.where(filterByYear).toList();
    birds = birds.where(filterBySpecies).toList();
    birds = birds.where(filterByAge).toList();

    return birds;
  }

  @override
  listAllItems(BuildContext context, AsyncSnapshot snapshot) {
    birds = getFilteredItems(snapshot);
    return ListView.builder(
        itemCount: birds.length,
        itemBuilder: (context, index) {
          return birds[index].getListTile(context);
        });
  }

}
