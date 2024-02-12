import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/models/nest.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';


class ListNests extends StatefulWidget {
  const ListNests({Key? key}) : super(key: key);

  @override
  State<ListNests> createState() => _ListNestsState();
}

class _ListNestsState extends State<ListNests> {
  int _selectedYear = DateTime.now().year;
  late SharedPreferencesService sps;
  CollectionReference birdCollection = FirebaseFirestore.instance.collection('Birds');
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
    Stream<QuerySnapshot> _birdsStream = birdCollection.snapshots();
    return Scaffold(
        appBar: AppBar(
          title: Text("Birds", style: TextStyle(color: Colors.black)),
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
                    hintText: "Search by band or nests",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    ),
                  ),
                ),
                Expanded(
                    child: StreamBuilder(
                        stream: _birdsStream,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasData) {
                            List<Bird> birds = snapshot.data!.docs
                                .map((DocumentSnapshot e) => Bird.fromQuerySnapshot(e))
                                 .where((Bird e) => e.nest_year == _selectedYear || e.ringed_date!.year == _selectedYear)
                                .where((Bird e) => e.band.contains(searchController.text) || e.color_band!.contains(searchController.text))
                                .toList();
                            return ListView(
                              children: [
                                ...birds.map((Bird e)=>e.getListTile(context))
                              ],
                            );
                          } else {
                            return Container(
                                padding: EdgeInsets.all(40.0),
                                child: Text("loading birds..."));
                          }
                        })),
              ],
            )));
  }

}