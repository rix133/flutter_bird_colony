import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/listScreenWidget.dart';
import 'package:kakrarahu/models/firestore/experiment.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';



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
    collection = widget.firestore.collection('experiments');
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
              backgroundColor: MaterialStateProperty.all(Colors.grey)
          )
      ),
    );
  }

  @override
  Future<void> executeDownload() {
    //get how many different year experiments are requested
    Set<int?> totalYears = items.map((e) => (e as Experiment).year).toSet();

    if(totalYears.length > 1){
      return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: Text("Download"),
              content: Text("Please select only one year to download"),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Close", style: TextStyle(color: Colors.black))),
              ],
            );
          });
    } else {
      DateTime? start = totalYears.isNotEmpty ? DateTime(totalYears.first!) : null;
      return (FSItemMixin()
          .downloadExcel(items, "experiments", widget.firestore, start: start));
    }

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

  getFilteredItems(AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
    List<Experiment> exps = snapshot.data!.docs
        .map<Experiment>((DocumentSnapshot<Object?> e) => Experiment.fromDocSnapshot(e))
        .toList();
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