import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/googleMapScreen.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/services/nestsService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapNests extends GoogleMapScreen {
  final FirebaseFirestore firestore;

  const MapNests({Key? key, required auth, required this.firestore})
      : super(key: key, auth: auth, autoUpdateLoc: false);

  @override
  FirebaseFirestore get firestoreInstance => firestore;

  @override
  _MapNestsState createState() => _MapNestsState();
}

class _MapNestsState extends GoogleMapScreenState {
  String today = DateTime.now().toIso8601String().split("T")[0];
  Stream<List<Nest>> _nestStream = Stream.empty();
  String visible = "";
  NestsService? nestsService;
  List<String>? bigFilter;

  final search = TextEditingController();
  ValueNotifier<Set<Marker>> markersToShow = ValueNotifier<Set<Marker>>({});

  @override
  void initState() {
    super.initState();
    String year = "";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var map = ModalRoute.of(context)!.settings.arguments;
      if (map != null) {
        map = map as Map<String, dynamic>;
        if (map["year"] != null) {
          year = nestCollectionNameFromYearOrName(map["year"]);
        }
        if (map["nest_ids"] != null) {
          bigFilter = map["nest_ids"] as List<String>;
        }
      }

      nestsService = Provider.of<NestsService>(context, listen: false);
      year = year.isNotEmpty
          ? year
          : yearToNestCollectionName(sps?.selectedYear ?? DateTime.now().year);
      _nestStream = nestsService!.watchItems(year);
      setState(() {});
    });
  }

  @override
  void dispose() {
    search.dispose();
    markersToShow.dispose();
    super.dispose();
  }

  void updateMarkersToShow(List<Nest> nests) {
    Set<Nest> nestsToShow = nests.toSet();

    if (bigFilter != null) {
      nestsToShow = nestsToShow
          .where((element) => bigFilter!.contains(element.id))
          .toSet();
    }
    if (search.text.isNotEmpty) {
      Set<String> searches = search.text.split(RegExp(r',\s*|\s+')).toSet();
      nestsToShow = nestsToShow.where((element) {
        for (String search in searches) {
          if (element.name.toLowerCase().contains(search.toLowerCase()) ||
              (element.species?.toLowerCase() ?? "").contains(search.toLowerCase()) ||
              (element.experiments?.any((element) => element.name.toLowerCase().contains(search.toLowerCase())) ?? false)) {
            return true;
          }
        }
        return false;
      }).toSet();
    }
    markersToShow.value = nestsToShow
        .map((e) => e.getMarker(context, true, sps?.markerColorGroups ?? [],
            selectedYear: sps?.selectedYear, isAdmin: sps?.isAdmin ?? false))
        .toSet();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextFormField(
            controller: search,
            style: TextStyle(color: Colors.black),
            onEditingComplete: () {
              setState(() {
                focus.unfocus();
                Navigator.pop(context, 'exit');
              });
            },
            focusNode: focus,
            decoration: InputDecoration(
              labelText: 'Search',
              hintText: 'nests or species',
              labelStyle: TextStyle(color: Colors.black),
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search),
              counterStyle: TextStyle(color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  @override
  List<Widget> floatingActionButtons() {
    List<Widget> buttons = baseFloatingActionButtons();
    buttons.addAll([
      SizedBox(height: 10),
      searchButton(),
      SizedBox(height: 10),
      lastFloatingButton(),
    ]);
    return buttons;
  }

  @override
  GestureDetector lastFloatingButton() {
    return GestureDetector(
      child: FloatingActionButton(
        heroTag: "addNest",
        onPressed: () {
          Navigator.pushNamed(context, '/createNest');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget searchButton() {
    return FloatingActionButton(
      heroTag: "search",
      onPressed: () => _showSearchDialog(),
      child: const Icon(Icons.search),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _nestStream,
        builder: (context, AsyncSnapshot<List<Nest>> snapshot) {
          List<Nest> nests =
              snapshot.hasData ? snapshot.data! : (nestsService?.items ?? []);
          updateMarkersToShow(nests);
          return ValueListenableBuilder<Set<Marker>>(
            valueListenable: markersToShow,
            builder: (context, value, child) {
              markers = value;
              return super.build(context);
            },
          );
        },
      ),
    );
  }
}
