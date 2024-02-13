import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/listOverviewPageButtons.dart';
import 'package:kakrarahu/models/bird.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

class ListBirds extends StatefulWidget {
  const ListBirds({Key? key}) : super(key: key);

  @override
  State<ListBirds> createState() => _ListBirdsState();
}

class _ListBirdsState extends State<ListBirds> {
  int _selectedYear = DateTime.now().year;
  late SharedPreferencesService sps;
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
          title: Text("Birds", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.tealAccent,
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
                        items: List<int>.generate(
                            DateTime.now().year - 2022 + 1,
                            (int index) => index + 2022).map((int year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString(),
                                style:
                                    TextStyle(color: Colors.deepPurpleAccent)),
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
                ),
                Expanded(
                    child: StreamBuilder(
                        stream: _birdsStream,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasData) {
                            List<Bird> birds = snapshot.data!.docs
                                .map((DocumentSnapshot e) =>
                                    Bird.fromQuerySnapshot(e))
                                .where((Bird e) =>
                                    e.nest_year == _selectedYear ||
                                    e.ringed_date!.year == _selectedYear)
                                .where((Bird e) =>
                                    e.band.toLowerCase().contains(
                                        searchController.text.toLowerCase()) ||
                                    (e.color_band != null
                                        ? e.color_band!.toLowerCase().contains(
                                            searchController.text.toLowerCase())
                                        : false))
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
              ],
            )));
  }
}
