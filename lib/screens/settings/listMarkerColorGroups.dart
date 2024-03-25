// Purpose: List all measures to define, edit or delete them allow to add new ones
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/markerColorGroup.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

class ListMarkerColorGroups extends StatefulWidget {
  final List<MarkerColorGroup> markers;
  final Function(List<MarkerColorGroup>) onMarkersUpdated;

  const ListMarkerColorGroups(
      {Key? key, required this.markers, required this.onMarkersUpdated})
      : super(key: key);

  @override
  _ListMarkerColorGroupsState createState() => _ListMarkerColorGroupsState();
}

class _ListMarkerColorGroupsState extends State<ListMarkerColorGroups> {
  SharedPreferencesService? sps;

  onSaved(MarkerColorGroup measure) {
    setState(() {
      widget.onMarkersUpdated(widget.markers);
    });
  }

  onRemoved(MarkerColorGroup measure) {
    setState(() {
      widget.markers.remove(measure);
      widget.onMarkersUpdated(widget.markers);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
    });
  }

  Widget getAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton.icon(
        key: Key("addMarkerColorGroupsButton"),
        onPressed: () {
            MarkerColorGroup newMeasure =
                MarkerColorGroup.magenta(sps?.defaultSpecies ?? "");
            widget.markers.add(newMeasure);
            onSaved(newMeasure);
          },
          icon: Icon(Icons.add),
          label: Padding(
            child: Text("Add marker color", style: TextStyle(fontSize: 14)),
            padding: EdgeInsets.all(10)),
      ),
    );
  }

  List<Widget> listAllItems(BuildContext context) {
    return widget.markers
        .map((e) => e.getListTile(context, onSaved, onRemoved, sps))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Custom colors",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 5,
        ),
        ...listAllItems(context),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getAddButton(context),
          ],
        ),
      ],
    );
  }
}
