import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/experimentedItem.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/services/experimentsService.dart';
import 'package:flutter_bird_colony/services/firestoreItemService.dart';
import 'package:provider/provider.dart';

import '../models/firestore/experiment.dart';
import '../services/sharedPreferencesService.dart';

abstract class ListScreenWidget<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final FirebaseFirestore firestore;
  const ListScreenWidget({Key? key, required this.title, required this.icon, required this.firestore}) : super(key: key);

  @override
  ListScreenWidgetState<T> createState();
}

abstract class ListScreenWidgetState<T> extends State<ListScreenWidget<T>> {
  int selectedYear = DateTime.now().year;
  String? selectedExperiments;
  Stream<List<FirestoreItem>> stream = Stream.empty();
  ExperimentsService? experimentsService;
  Stream<List<Experiment>> experimentStream = Stream.empty();
  TextEditingController searchController = TextEditingController();
  bool downloading = false;
  String collectionName = "";
  FirestoreItemService? fsService;

  SharedPreferencesService? sps;

  List<FirestoreItem> get items => getFilteredItems(fsService?.items ?? []);

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
      experimentsService =
          Provider.of<ExperimentsService>(context, listen: false);
      stream = fsService?.watchItems(collectionName) ?? Stream.empty();
      experimentStream =
          experimentsService?.watchItems("experiments") ?? Stream.empty();

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
          selectedYear = newValue ?? selectedYear;
          updateYearFilter(selectedYear);
          Navigator.pop(context);
        });
      },
    );
  }

  updateYearFilter(int value);


  Future<void> executeDownload();

  Widget getAddButton(BuildContext context);

  Future<bool> _downloadConfirmationDialog(BuildContext context) {
    bool admin = sps?.isAdmin ?? false;
    if (admin) {
      return Future.value(true);
    } else {
      return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text("Download"),
              content: Text(
                  "To get selected ${widget.title} to Excel contact an administrator."),
              actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                    child: Text("OK", style: TextStyle(color: Colors.black))),
              ],
          );
        }).then((value) => value ?? false);
    }
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

  List<FirestoreItem> getFilteredItems(List<FirestoreItem> items);

  ListView listAllItems(BuildContext context, List<FirestoreItem> items) {
    //disable if not current year and user is not admin
    bool disabled =
        selectedYear != DateTime.now().year && !(sps?.isAdmin ?? false);
    items = getFilteredItems(items);
    return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return items[index].getListTile(context, widget.firestore,
              disabled: disabled, groups: sps?.markerColorGroups ?? []);
        });
  }


  Widget experimentInput(BuildContext context) {
    return StreamBuilder<List<Experiment>>(
      stream: experimentStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return DropdownButton<String>(
          value: selectedExperiments,
          style: TextStyle(color: Colors.deepPurpleAccent),
          items: snapshot.data!.map((Experiment e) {
            return DropdownMenuItem<String>(
              value: e.name,
              child: Text(e.name,
                  style: TextStyle(color: Colors.deepPurpleAccent)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedExperiments = newValue;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            SizedBox(height: 20,),
            Row(children: [
              Expanded(child: TextField(
                    key: Key("searchTextField"),
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
                        builder: (context,
                            AsyncSnapshot<List<FirestoreItem>> snapshot) {
                          if (snapshot.hasData) {
                            return (listAllItems(context, snapshot.data!));
                          } else if (snapshot.hasError) {
                            return Container(
                                padding: EdgeInsets.all(40.0),
                                child: Text("Error loading items"));
                          } else {
                            if (fsService?.items.length == 0) {
                              return Container(
                                  padding: EdgeInsets.all(40.0),
                                  child: Text("loading items..."));
                            } else {
                              return listAllItems(
                                  context, fsService?.items ?? []);
                            }
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
        )));
  }
}