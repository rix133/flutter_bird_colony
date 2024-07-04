import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/icons/my_flutter_app_icons.dart';
import 'package:flutter_bird_colony/screens/bird/listBirds.dart';
import 'package:flutter_bird_colony/screens/experiment/listExperiments.dart';
import 'package:flutter_bird_colony/screens/nest/listNests.dart';

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
            unselectedLabelColor: Colors.amberAccent,
            labelColor: Colors.white,
            tabs: [
              Tab(
                  icon: Icon(Icons.science, color: Colors.amberAccent),
                  text: "Experiments"),
              Tab(
                  icon: Icon(Icons.home, color: Colors.amberAccent),
                  text: "Nests"),
              Tab(
                  icon: Icon(CustomIcons.bird, color: Colors.amberAccent),
                  text: "Birds"),
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