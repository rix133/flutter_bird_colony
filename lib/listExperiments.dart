import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/listOverviewPageButtons.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';


class ListExperiments extends StatefulWidget {
  const ListExperiments({Key? key}) : super(key: key);

  @override
  State<ListExperiments> createState() => _ListExperimentsState();
}

class _ListExperimentsState extends State<ListExperiments> {
  int _selectedYear = DateTime.now().year;
  late SharedPreferencesService sps;
  CollectionReference experiments = FirebaseFirestore.instance.collection('experiments');
  TextEditingController searchController = TextEditingController();
  Stream<QuerySnapshot> _experimentsStream = Stream.empty();
  List<Experiment> exps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
     _experimentsStream = experiments.snapshots();
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Experiments", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.redAccent,
        ),
        body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                listOverviewPageButtons(context),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Select year:'),
                      Container(width: 8),
                      DropdownButton<int>(
                        value: _selectedYear,
                        items: List<int>.generate(DateTime.now().year - 2022 + 1, (int index) => index + 2022)
                            .map((int year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString(), style: TextStyle(color: Colors.deepPurpleAccent)),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedYear = newValue!;
                          });
                        },
                      )
                    ]),
                TextField(
                  controller: searchController,
                  onChanged: (String value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: "Search",
                    hintText: "Search by name or nests",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    ),
                  ),
                ),
                Expanded(
                    child: StreamBuilder(
                        stream: _experimentsStream,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasData) {
                            exps = snapshot.data!.docs
                                .map((DocumentSnapshot e) => Experiment.fromQuerySnapshot(e))
                                 .where((Experiment e) => e.year == _selectedYear)
                                .where((Experiment e) => e.name.toLowerCase().contains(searchController.text.toLowerCase()) || (e.nests?.contains(searchController.text) ?? false))
                                .toList();
                            return ListView(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                              children: [
                                ...exps.map((Experiment e)=>e.getListTile(context, sps.userName))
                              ],
                            );
                          } else {
                            return Container(
                                padding: EdgeInsets.all(40.0),
                                child: Text("loading experiments..."));
                          }
                        })),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                    child:Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getAddButton(context),
                    getDownloadButton(context)
                  ],))
              ]),
            ));
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

  getDownloadButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: IconButton(
          onPressed: () {
            FSItemMixin().downloadExcel(exps, "experiments");
          },
          icon: Icon(Icons.download),
     style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey)
          )
      ),
    );
  }

}