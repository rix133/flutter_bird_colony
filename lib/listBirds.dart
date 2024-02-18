import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/listOverviewPageButtons.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/species.dart';
import 'package:provider/provider.dart';

import 'models/experiment.dart';
import 'models/firestoreItemMixin.dart';

class ListBirds extends StatefulWidget {
  const ListBirds({Key? key}) : super(key: key);

  @override
  State<ListBirds> createState() => _ListBirdsState();
}

class _ListBirdsState extends State<ListBirds> {
  int _selectedYear = DateTime.now().year;
  String? _selectedExperiments;
  String? _selectedSpecies;
  int? _selectedAge;
  List<Experiment> allExperiments = [];
  List<Species> allSpecies = SpeciesList.english;


  SharedPreferencesService? sps;
  List<Bird> birds = [];
  CollectionReference birdCollection =
      FirebaseFirestore.instance.collection('Birds');
  TextEditingController searchController = TextEditingController();
  Stream<QuerySnapshot> _birdsStream = Stream.empty();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      _birdsStream = birdCollection.snapshots();
      FirebaseFirestore.instance.collection('experiments').get().then((value) {
        allExperiments = value.docs.map((e) => Experiment.fromQuerySnapshot(e)).toList();
      });

      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
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

  getDownloadButton(BuildContext context, SharedPreferencesService? sps) {
    if(sps == null){return Container();}
    if(sps.isAdmin == false){return Container();}
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: IconButton(
          onPressed: () {
            FSItemMixin().downloadExcel(birds, "birds");
          },
          icon: Icon(Icons.download),
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
              content: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Row(children: [
                        Text("Year"),
                        SizedBox(width: 20,),
                        DropdownButton<int>(
                          value: _selectedYear,
                          style: TextStyle(color: Colors.deepPurpleAccent),
                          items: List<int>.generate(
                              DateTime.now().year - 2022 + 1,
                                  (int index) => index + 2022).map((int year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString(),
                                  style: TextStyle(color: Colors.deepPurpleAccent)),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedYear = newValue!;
                            });
                          },
                        )
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        Text("Experiment"),
                        SizedBox(width: 20,),
                        DropdownButton<String>(
                          value: _selectedExperiments,
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
                              _selectedExperiments = newValue;
                            });
                          },
                        )
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        SizedBox(width: 10,),
                        Text("Species"),
                        DropdownButton<String>(
                          value: _selectedSpecies,
                          style: TextStyle(color: Colors.deepPurpleAccent),
                          items: allSpecies.map((Species e) {
                            return DropdownMenuItem<String>(
                              value: e.english,
                              child: Text(e.english == null ? "All" : e.english,
                                  style: TextStyle(color: Colors.deepPurpleAccent)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSpecies = newValue;
                            });
                          },
                        )
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Row(children: [
                        Text("Age"),
                        SizedBox(width: 20,),
                        DropdownButton<int>(
                          value: _selectedAge,
                          style: TextStyle(color: Colors.deepPurpleAccent),
                          items: [null,0,1,2,3,4,5,6,7,8,9,10].map((int? e) {
                            return DropdownMenuItem<int>(
                              value: e,
                              child: Text(e == null ? "All" : e.toString(),
                                  style: TextStyle(color: Colors.deepPurpleAccent)),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedAge = newValue;
                            });
                          },
                        )
                      ]),
                    ),
                  ),]),
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
    return e.nest_year == _selectedYear || e.ringed_date!.year == _selectedYear;
  }

  bool filterByText(Bird e) {
    return e.band.toLowerCase().contains(searchController.text.toLowerCase()) ||
        (e.color_band != null ? e.color_band!.toLowerCase().contains(searchController.text.toLowerCase()) : false);
  }

  bool filterByExperiments(Bird e) {
    if(_selectedExperiments == null) return true;
    return e.experiments?.map((e) => e.name).contains(_selectedExperiments) ?? false;
  }
  bool filterBySpecies(Bird e) {
    if(_selectedSpecies == null) return true;
    return e.species == _selectedSpecies;
  }
  bool filterByAge(Bird e) {
    if(_selectedAge == null) return true;
    return e.ageInYears() == _selectedAge;
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Birds", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.tealAccent,
        ),
        body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                listOverviewPageButtons(context),
                SizedBox(height: 20,),
                Row(children:[Expanded(child:TextField(
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
                        stream: _birdsStream,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasData) {
                            birds = snapshot.data!.docs
                                .map((DocumentSnapshot e) => Bird.fromQuerySnapshot(e))
                                .where(filterByYear)
                                .where(filterByText)
                                .where(filterByExperiments)
                                .where(filterBySpecies)
                                .where(filterByAge)
                                .toList();
                            return ListView(
                              children: [
                                ...birds.map((Bird e) => e.getListTile(context))
                              ],
                            );
                          } else {
                            return Container(
                                padding: EdgeInsets.all(40.0),
                                child: Text("loading birds..."));
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
