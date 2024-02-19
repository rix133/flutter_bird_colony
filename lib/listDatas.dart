import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import 'listBirds.dart';
import 'listExperiments.dart';
import 'listNests.dart';

class ListDatas extends StatelessWidget {
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
              Tab(icon: Icon(LineIcons.twitter), text: "Birds"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListExperiments(),
            ListNests(),
            ListBirds(),
          ],
        ),
      ),
    );
  }
}