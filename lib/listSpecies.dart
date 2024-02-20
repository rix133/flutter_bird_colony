import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestoreItemMixin.dart';
import 'package:kakrarahu/models/species.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

class ListSpecies extends StatefulWidget {
  const ListSpecies({Key? key}) : super(key: key);

  @override
  State<ListSpecies> createState() => _ListSpeciesState();
}

class _ListSpeciesState extends State<ListSpecies> {
  SharedPreferencesService? sps;
  CollectionReference? speciesCollection;
  TextEditingController searchController = TextEditingController();
  Stream<QuerySnapshot> _speciesStream = Stream.empty();
  List<Species> species = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);

      _speciesStream = FirebaseFirestore.instance
          .collection('settings')
          .doc(sps!.settingsType)
          .collection("species")
          .snapshots();
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
          title: Text('List Species'),
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(children: [Padding(padding: EdgeInsets.all(10),child:
            TextField(
              controller: searchController,
              onChanged: (String value) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: "Search",
                hintText: "Search by name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            )),
            Expanded(
                child: StreamBuilder(
                    stream: _speciesStream,
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        species = snapshot.data!.docs
                            .map((DocumentSnapshot e) =>
                                Species.fromDocSnapshot(e))
                            .where((Species e) =>
                                e.local.toLowerCase().contains(
                                    searchController.text.toLowerCase()) ||
                                (e.english.toLowerCase().contains(
                                            searchController.text
                                                .toLowerCase()) ||
                                    ( e.latin != null
                                    ? (e.latin!.toLowerCase().contains(
                                        searchController.text.toLowerCase()))
                                    : false)))
                            .toList();
                        return ListView(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 20),
                          children: [
                            ...species
                                .map((Species e) => e.getListTile(context))
                          ],
                        );
                      } else {
                        return Container(
                            padding: EdgeInsets.all(40.0),
                            child: Text("loading species..."));
                      }
                    })),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [getAddButton(context), getDownloadButton(context)],
                ))
          ]),
        ));
  }

  getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/editSpecies');
          },
          icon: Icon(Icons.add),
          label: Padding(
              child: Text("Add Species", style: TextStyle(fontSize: 18)),
              padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey))),
    );
  }

  getDownloadButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: IconButton(
          onPressed: () {
            FSItemMixin().downloadExcel(species, "species");
          },
          icon: Icon(Icons.download),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey))),
    );
  }
}
