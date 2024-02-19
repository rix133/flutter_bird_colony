
import 'package:flutter_compass/flutter_compass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

import 'models/nest.dart';

class NestsMap extends StatefulWidget {
  const NestsMap({Key? key}) : super(key: key);

  @override
  State<NestsMap> createState() => _NestsMapState();
}

class _NestsMapState extends State<NestsMap> {
  var today = DateTime.now().toIso8601String().split("T")[0];
  static const kakrarahud = CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 270,
    zoom: 16.35,
  );

  GoogleMapController? _googleMapController;
  Stream<Position> loc = Stream.empty();
  Stream<QuerySnapshot> _nestStream = Stream.empty();
  String visible = "";
  SharedPreferencesService? sps;

  CollectionReference pesa =
      FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  Set<Circle> circle = {
    Circle(
      circleId: CircleId("myLocEmpty"),
    )
  };
  final search = TextEditingController();
  final focus = FocusNode();
  ValueNotifier<Set<Marker>> markersToShow = ValueNotifier<Set<Marker>>({});
  Set <Nest> nests = {};
  Query? query;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      var map = ModalRoute.of(context)!.settings.arguments;
      if(map != null){
        map = map as Map<String, dynamic>;
        if(map?["nest_ids"] != null){
          print(map?["nest_ids"]);
          query = pesa.where(FieldPath.documentId, whereIn: map?["nest_ids"]);
        }
      }
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      _nestStream = query?.snapshots() ?? pesa.snapshots();
      loc = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
      ));

      updateMarkersToShow();
      setState(() {});
    });
  }

  @override
  void dispose() {
    search.dispose();
    focus.dispose();
    _googleMapController?.dispose();
    markersToShow.dispose();
    super.dispose();
  }

  updateMarkersToShow() {
    Set<Nest> nestsToShow = nests;
    if(search.text.isNotEmpty){
      //split by comma and space
      Set<String> searches = search.text.split(RegExp(r',\s*|\s+')).toSet();
      nestsToShow = nests.where((element) {
        for (String search in searches) {
          if (element.name.toLowerCase().contains(search.toLowerCase()) ||
              (element.species?.toLowerCase() ?? "").contains(search.toLowerCase()) ||
              (element.experiments?.any((element) => element.name.toLowerCase().contains(search.toLowerCase())) ?? false)) {
            return true;
          }
        }
        return false;
      }).toSet();
    } else {
      nestsToShow = nests;
    }
    markersToShow.value = nestsToShow.map((e) => e.getMarker(context, true)).toSet();
    markersToShow.notifyListeners();
  }


  void handleNestChanges(BuildContext context, QuerySnapshot snapshot) {
    Nest snap;
    snapshot.docChanges.forEach((DocumentChange<Object?> change) {
      if (change.type == DocumentChangeType.added) {
        snap = Nest.fromDocSnapshot(change.doc);
        nests.add(snap);
      }
      if (change.type == DocumentChangeType.modified) {
        snap = Nest.fromDocSnapshot(change.doc);
        nests.removeWhere((element) => element.id == snap.id);
        nests.add(snap);
      }
      if (change.type == DocumentChangeType.removed) {
        snap = Nest.fromDocSnapshot(change.doc);
        nests.removeWhere((element) => element.id == snap.id);
      }
      updateMarkersToShow();
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: _nestStream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              handleNestChanges(context, snapshot.data!);
              return Column(
                children: [
                  Flexible(
                    child: ValueListenableBuilder<Set<Marker>>(
                      valueListenable: markersToShow,
                      builder: (context, value, child) {
                        return GoogleMap(
                          circles: circle,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          markers: value,
                          mapType: MapType.satellite,
                          zoomControlsEnabled: false,
                          initialCameraPosition: kakrarahud,
                          onMapCreated: (controller) =>
                          _googleMapController = controller,
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StreamBuilder<Position>(
              stream: loc,
              builder: (context, AsyncSnapshot<Position> snapshot) {
                if (snapshot.hasData == false) {
                  Text("");
                }
                return StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot1) {
                      return Column(
                        children: [
                          FloatingActionButton(
                            heroTag: "compass",
                            onPressed: () {
                              _googleMapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(CameraPosition(
                                target: LatLng(
                                    snapshot.data?.latitude ?? 58.766218,
                                    snapshot.data?.longitude ?? 23.430432),
                                bearing: snapshot1.hasData
                                    ? snapshot1.data!.heading ?? 270
                                    : 270,
                                zoom: 19.85,
                              )));
                            },
                            child: const Icon(Icons.compass_calibration),
                          ),
                          SizedBox(height: 5),
                          FloatingActionButton(
                            heroTag: "myLoc",
                            onPressed: () {
                              _googleMapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(CameraPosition(
                                target: LatLng(
                                    snapshot.data?.latitude ?? 58.766218,
                                    snapshot.data?.longitude ?? 23.430432),
                                bearing: snapshot1.hasData
                                    ? snapshot1.data!.heading ?? 270
                                    : 270,
                                zoom: 19.85,
                              )));
                              if (mounted) {
                                setState(() {
                                  circle = {
                                    Circle(
                                      circleId: CircleId("myLoc"),
                                      radius: snapshot.data?.accuracy ?? 200,
                                      center: LatLng(
                                          snapshot.data?.latitude ?? 58.766218,
                                          snapshot.data?.longitude ??
                                              23.430432),
                                      strokeColor: Colors.orange,
                                    )
                                  };
                                });
                              }
                              focus.unfocus();
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ],
                      );
                    });
              }),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: "zoomOut",
            onPressed: () {
              _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(kakrarahud));
              focus.unfocus();
            },
            child: const Icon(Icons.zoom_out_map),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: "search",
            isExtended: false,
            onPressed: () {
              _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(kakrarahud));
              focus.unfocus();
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Stack(
                        children: [
                          TextFormField(
                            style: TextStyle(color: Colors.blue, fontSize: 20),
                            controller: search,
                            onEditingComplete: () async {
                              setState(() {
                                updateMarkersToShow();
                                focus.unfocus();
                                Navigator.pop(context, 'exit');
                              });
                            },
                            textAlign: TextAlign.center,
                            focusNode: focus,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 35),
                              fillColor: Colors.orange,
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide:
                                      (BorderSide(color: Colors.indigo))),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                                borderSide: BorderSide(
                                  color: Colors.deepOrange,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  });
            },
            child: const Icon(Icons.search),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: "addNest",
            onPressed: () {
              Navigator.pushNamed(context, "/nestCreate");
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
