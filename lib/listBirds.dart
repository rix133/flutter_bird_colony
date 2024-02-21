import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:kakrarahu/models/species.dart';
import 'package:provider/provider.dart';

import 'design/experimentDropdown.dart';
import 'design/yearDropdown.dart';
import 'models/experiment.dart';
import 'models/firestoreItemMixin.dart';
import 'design/speciesRawAutocomplete.dart';

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
  FocusNode _focusNode = FocusNode();
  List<Experiment> allExperiments = [];


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
    _focusNode.dispose();
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

  updateYearFilter(int year) {
    setState(() {
      _selectedYear = year;
    });
  }

  updateExperimentFilter(String? experiment) {
    setState(() {
      _selectedExperiments = experiment;
    });
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
                YearDropdown(
                selectedYear: _selectedYear,
                onChanged: updateYearFilter,
              ),

                  ExperimentDropdown(
                    allExperiments: allExperiments,
                    selectedExperiment: _selectedExperiments,
                    onChanged: updateExperimentFilter,
                  ),
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
    return e.nest_year == _selectedYear || e.ringed_date.year == _selectedYear;
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
    return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
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
                                .map((DocumentSnapshot e) => Bird.fromDocSnapshot(e))
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
            ));
  }
}
