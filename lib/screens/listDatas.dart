import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/icons/my_flutter_app_icons.dart';
import 'package:kakrarahu/screens/bird/listBirds.dart';
import 'package:kakrarahu/screens/experiment/listExperiments.dart';
import 'package:kakrarahu/screens/nest/listNests.dart';

class ListDatas extends StatelessWidget {
  final FirebaseFirestore firestore;
  const ListDatas({Key? key, required this.firestore}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Data"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.science), text: "Experiments"),
              Tab(icon: Icon(Icons.home), text: "Nests"),
              Tab(icon: Icon(CustomIcons.bird), text: "Birds"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListExperiments(firestore: firestore,),
            ListNests(firestore: firestore,),
            ListBirds(firestore: firestore,),
          ],
        ),
      ),
    );
  }
}