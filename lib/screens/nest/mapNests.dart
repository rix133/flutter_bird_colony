
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/services/nestsService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/firestore/nest.dart';

class MapNests extends StatefulWidget {
  final FirebaseFirestore firestore;
  const MapNests({Key? key, required this.firestore})  : super(key: key);

  @override
  State<MapNests> createState() => _MapNestsState();
}

class _MapNestsState extends State<MapNests> {
  String today = DateTime.now().toIso8601String().split("T")[0];
  CameraPosition initCamera = CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 270,
    zoom: 16.35,
  );
  bool _locOK = false;
  GoogleMapController? _googleMapController;
  Stream<Position> loc = Stream.empty();
  Stream<List<Nest>> _nestStream = Stream.empty();
  String visible = "";
  NestsService? nestsService;
  SharedPreferencesService? sps;

  Set<Circle> circle = {
    Circle(
      circleId: CircleId("myLocEmpty"),
    )
  };
  final search = TextEditingController();
  final focus = FocusNode();
  ValueNotifier<Set<Marker>> markersToShow = ValueNotifier<Set<Marker>>({});
  Query? query;
  List<String>? bigFilter;
  LocationService location = LocationService.instance;
  AuthService auth = AuthService.instance;

  _setDefaultLocation(CameraPosition cameraPosition) {
    initCamera = cameraPosition;
  }

  @override
  initState() {
    super.initState();
    String year = DateTime.now().year.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      auth.isUserSignedIn().then((value) {
        if (value == false) {
          Navigator.pushReplacementNamed(context, "/settings");
        }
      });
      location.determinePosition(context, _locOK).then((value) => _locOK);
      var map = ModalRoute.of(context)!.settings.arguments;
      if(map != null){
        map = map as Map<String, dynamic>;
        if (map["year"] != null) {
          year = map["year"].toString();
        }
        if(map["nest_ids"] != null) {
          bigFilter = map["nest_ids"] as List<String>;
        }
      }
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      nestsService = Provider.of<NestsService>(context, listen: false);
      _setDefaultLocation(sps!.defaultLocation);
      //take the latest stream snapshot and update the markers
      _nestStream = nestsService!.watchItems(year);
      //init the markers
      //updateMarkersToShow(nestsService?.items ?? []);
      loc = location.getPositionStream();
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

  updateMarkersToShow(List<Nest> nests) {
    Set<Nest> nestsToShow = nests.toSet();
    //apply the bigfilter

    if (bigFilter != null) {
      nestsToShow = nestsToShow
          .where((element) => bigFilter!.contains(element.id))
          .toSet();
    }
    if(search.text.isNotEmpty){
      //split by comma and space
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
        .map((e) => e.getMarker(context, true, sps?.markerColorGroups ?? []))
        .toSet();
  }



  _updateCameraPosition(AsyncSnapshot snapshot, AsyncSnapshot<CompassEvent> snapshot1) {
    _googleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(
              snapshot.data?.latitude ?? initCamera.target.latitude,
              snapshot.data?.longitude ?? initCamera.target.longitude),
          bearing: snapshot1.hasData
              ? snapshot1.data!.heading ?? initCamera.bearing
              : initCamera.bearing,
          zoom: initCamera.zoom,
        )));
  }

  Column nestsMap() {
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
                initialCameraPosition: initCamera,
                onMapCreated: (controller) => _googleMapController = controller,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: _nestStream,
          builder: (context, AsyncSnapshot<List<Nest>> snapshot) {
            List<Nest> nests =
                snapshot.hasData ? snapshot.data! : (nestsService?.items ?? []);
            updateMarkersToShow(nests);
            return nestsMap();
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
                              _updateCameraPosition(snapshot, snapshot1);
                              focus.unfocus();
                            },
                            child: const Icon(Icons.compass_calibration),
                          ),
                          SizedBox(height: 5),
                          FloatingActionButton(
                            heroTag: "myLoc",
                            onPressed: () {
                             _updateCameraPosition(snapshot, snapshot1);
                              if (mounted) {
                                setState(() {
                                  circle = {
                                    Circle(
                                      circleId: CircleId("myLoc"),
                                      radius: snapshot.data?.accuracy ?? 200,
                                      center: LatLng(
                                          snapshot.data?.latitude ?? initCamera.target.latitude,
                                          snapshot.data?.longitude ?? initCamera.target.longitude),
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
              _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(initCamera));
              focus.unfocus();
            },
            child: const Icon(Icons.zoom_out_map),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            heroTag: "search",
            isExtended: false,
            onPressed: () {
              _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(initCamera));
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
              Navigator.pushNamed(context, '/createNest');
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
