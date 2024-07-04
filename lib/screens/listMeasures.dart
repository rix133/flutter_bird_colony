// Purpose: List all measures to define, edit or delete them allow to add new ones
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/measure.dart';
import '../services/sharedPreferencesService.dart';

class ListMeasures extends StatefulWidget {
  final List<Measure> measures;
  final Function(List<Measure>) onMeasuresUpdated;

  const ListMeasures({Key? key, required this.measures, required this.onMeasuresUpdated}) : super(key: key);

  @override
  _ListMeasuresState createState() => _ListMeasuresState();
}


class _ListMeasuresState extends State<ListMeasures>{
  List<Measure> filteredMeasures = [];
  TextEditingController searchController = TextEditingController();
  SharedPreferencesService? sps;


  onSaved(Measure measure) {
    setState(() {
      widget.onMeasuresUpdated(widget.measures);
    });
  }
  onRemoved(Measure measure) {
    setState(() {
      widget.measures.remove(measure);
      widget.onMeasuresUpdated(widget.measures);
    });
  }


  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
    });
  }


  void clearFilters() {
    setState(() {
      searchController.clear();
    });
  }
  bool filterByType(String? type) {
    if (type == null) return true;
    return widget.measures.contains((element) => element.type == type);
  }



  Widget getAddButton(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ElevatedButton.icon(
          key: Key("addMeasureButton"),
          onPressed: () {
            Measure newMeasure = Measure(name: "", type: "any", value: "", unit: "", isNumber: false, modified: DateTime.now());
            widget.measures.add(newMeasure);
            onSaved(newMeasure);
          },
          icon: Icon(Icons.add),
          label: Padding(
              child: Text("Add measure", style: TextStyle(fontSize: 18)),
              padding: EdgeInsets.all(12)),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.grey)
          )
      ),
    );
  }

  List<Measure> getFilteredItems() {
    if (searchController.text.isEmpty) return widget.measures;
    return widget.measures.where((element) => element.name.toLowerCase().contains(searchController.text.toLowerCase()) || element.type.toLowerCase().contains(searchController.text.toLowerCase())).toList();
  }

  List<Widget> listAllItems(BuildContext context) {
    filteredMeasures = getFilteredItems();
    return filteredMeasures.map((e) => e.getListTile(context, onSaved, onRemoved)).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Text("Measures", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 5,),
            widget.measures.length > 5
                ? Row(children: [
                    Expanded(child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: "Search",
                  hintText: "Search by name or type",
                  prefixIcon: Icon(Icons.search),
                ),
              )),
                  ])
                : Container(),
            widget.measures.length > 5
                ? SizedBox(
                    height: 20,
                  )
                : Container(),
            ...listAllItems(context),
          Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getAddButton(context),
                  ],),
          ],
        ));
  }
}