import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/experimentedItem.dart';
import 'package:provider/provider.dart';
import '../models/experiment.dart';
import '../services/sharedPreferencesService.dart';

abstract class ListScreenWidget<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  const ListScreenWidget({Key? key, required this.title, required this.icon}) : super(key: key);

  @override
  ListScreenWidgetState<T> createState();
}

abstract class ListScreenWidgetState<T> extends State<ListScreenWidget<T>> {
  int selectedYear = DateTime.now().year;
  String? selectedExperiments;
  Stream<QuerySnapshot> stream = Stream.empty();
  CollectionReference? collection;
  List<Experiment> allExperiments = [];
  TextEditingController searchController = TextEditingController();
  bool downloading = false;


  SharedPreferencesService? sps;
  List<T> items = [];

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      print(sps!.userEmail);
      stream = collection?.snapshots() ?? Stream.empty();
      FirebaseFirestore.instance.collection('experiments').get().then((value) {
        allExperiments =
            value.docs.map((e) => Experiment.fromDocSnapshot(e)).toList();
      });

      setState(() {});
    });
  }

  void clearFilters() {
    setState(() {
      selectedYear = DateTime.now().year;
      selectedExperiments = null;
      searchController.clear();
    });
  }
  bool filterByExperiments(ExperimentedItem e) {
    if (selectedExperiments == null) return true;
    return e.experiments?.map((e) => e.name).contains(selectedExperiments) ??
        false;
  }



  Widget yearInput(BuildContext context) {
    return DropdownButton<int>(
      value: selectedYear,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: List<int>.generate(DateTime.now().year - 2022 + 1,
              (int index) => index + 2022).map((int year) {
        return DropdownMenuItem<int>(
          value: year,
          child: Text(year.toString(),
              style: TextStyle(color: Colors.deepPurpleAccent)),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          selectedYear = newValue!;
          Navigator.pop(context);
        });
      },
    );
  }

  updateYearFilter(int value);

  Padding getMinMaxInput(BuildContext context, String label, Function(String) minFun, Function(String) maxFun, double? min, double? max) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        Text(label),
        SizedBox(width: 10),
        Expanded(child:TextFormField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Min",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
            ),
            initialValue: min?.toString() ?? "",
            onChanged: minFun
        )),
        SizedBox(width: 10),
        Expanded(child:TextFormField(
            keyboardType: TextInputType.number,
            initialValue: max?.toString() ?? "",
            decoration: InputDecoration(
              labelText: "Max",

              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
            ),
            onChanged: maxFun
        )),
      ]),
    );
  }

  Future<void> executeDownload();

  Widget getAddButton(BuildContext context);

  Future<bool> _downloadConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text("Download"),
            content: Text("Download all selected ${widget.title} to Excel?"),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text("No", style: TextStyle(color: Colors.black))),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text("Yes", style: TextStyle(color: Colors.red))),
            ],
          );
        }).then((value) => value ?? false);
  }

  getDownloadButton(BuildContext context, SharedPreferencesService? sps) {
    if (sps == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: downloading ? CircularProgressIndicator() : IconButton(
          onPressed: () {
            setState(() {
              downloading = true;
            });
            _downloadConfirmationDialog(context).then((bool value) => {
              if(value){
                executeDownload().then((value) => setState(() {
                  downloading = false;
                })),
              } else {
                setState(() {
                  downloading = false;
                })}});

          },
          icon: Icon(Icons.download),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey))),
    );
  }

  bool filterByText(T item);

  void openFilterDialog(BuildContext context);

  ListView listAllItems(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot);


  Widget experimentInput(BuildContext context) {
    return DropdownButton<String>(
      value: selectedExperiments,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: allExperiments.map((Experiment e) {
        return DropdownMenuItem<String>(
          value: e.name,
          child: Text(e.name,
              style: TextStyle(color: Colors.deepPurpleAccent)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedExperiments = newValue;
          Navigator.pop(context);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            SizedBox(height: 20,),
            Row(children: [
              Expanded(child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: "Search",
                  hintText: "Search by band or nests",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
              )),
              ElevatedButton.icon(
                  onPressed: () => openFilterDialog(context),
                  icon: Icon(Icons.filter_alt),
                  label: Padding(child:Text("Filter", style: TextStyle(fontSize: 18)), padding: EdgeInsets.all(12)),
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.grey)
                  )
              ),
            ]),
            SizedBox(height: 20,),
            Expanded(
                child: StreamBuilder(
                    stream: stream,
                    builder:
                        (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        return(listAllItems(context, snapshot));
                      } else {
                        return Container(
                            padding: EdgeInsets.all(40.0),
                            child: Text("loading items..."));
                      }
                    })),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child:Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getAddButton(context),
                    getDownloadButton(context, sps)
                  ],)),
          ],
        ));
  }
}