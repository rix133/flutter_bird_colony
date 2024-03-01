import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/icons/my_flutter_app_icons.dart';

import 'listBirds.dart';
import 'listExperiments.dart';
import 'nest/listNests.dart';

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
              Tab(icon: Icon(MyFlutterApp.bird), text: "Birds"),
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