import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/listScreenWidget.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:provider/provider.dart';

import '../../models/firestore/firestoreItem.dart';
import '../../services/experimentsService.dart';

class ListExperiments extends ListScreenWidget<Experiment> {
  const ListExperiments({Key? key, required FirebaseFirestore firestore}) : super(key: key, title: 'experiments with nests and eggs', icon: Icons.science, firestore: firestore);

  @override
  ListScreenWidgetState<Experiment> createState() => _ListExperimentsState();
}

class _ListExperimentsState extends ListScreenWidgetState<Experiment> {
  CollectionReference? collection;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  initState() {
    collectionName = 'experiments';
    fsService = Provider.of<ExperimentsService>(context, listen: false);
    super.initState();
  }

  getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/editExperiment');
          },
          icon: Icon(Icons.add),
          label: Padding(child:Text("Add Experiment", style: TextStyle(fontSize: 18)), padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey)
          )
      ),
    );
  }

  @override
  Future<void> executeDownload() {
    //get how many different year experiments are requested
    Set<int?> totalYears = items.map((e) => (e as Experiment).year).toSet();
      DateTime? start = totalYears.isNotEmpty ? DateTime(totalYears.first!) : null;
      return (FSItemMixin()
          .downloadExcel(items, "experiments", widget.firestore, start: start));

  }

  bool filterByText(Experiment e) {
    return e.name.toLowerCase().contains(searchController.text.toLowerCase()) ||
        e.measures.any((element) =>
        !element.isNumber &&
            element.value.toLowerCase().contains(
                searchController.text.toLowerCase())) || // search note texts
        (e.nests != null
            ? e.nests!.any((element) => element.toLowerCase()
            .contains(searchController.text.toLowerCase()))
            : false);
  }


  bool filterByYear(Experiment e) {
    return e.year == selectedYear;
  }
  updateYearFilter(int value) {
    setState(() {
      selectedYear = value;
    });
  }

  getFilteredItems(List<FirestoreItem> items) {
    List<Experiment> exps = items.map((e) => e as Experiment).toList();
    exps = exps.where(filterByText).toList();
    exps = exps.where(filterByYear).toList();
    return exps;
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


}
