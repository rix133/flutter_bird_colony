import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/experiment.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  Widget build(BuildContext context) {
    Stream<QuerySnapshot> _experimentsStream = experiments.snapshots();
    return Scaffold(
        appBar: AppBar(
          title: Text("Experiments", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.amberAccent,
        ),
        body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
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
                            List<Experiment> exps = snapshot.data!.docs
                                .map((DocumentSnapshot e) => Experiment.fromQuerySnapshot(e))
                                 .where((Experiment e) => e.year == _selectedYear)
                                .where((Experiment e) => e.name.contains(searchController.text) || e.nests!.contains(searchController.text))
                                .toList();
                            return ListView(
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
              ],
            )));
  }

}