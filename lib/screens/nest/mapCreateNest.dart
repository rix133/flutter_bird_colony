import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/services/authService.dart';
import 'package:flutter_bird_colony/services/locationService.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/firestore/nest.dart';
import '../../models/measure.dart';


class MapCreateNest extends StatefulWidget {
  final FirebaseFirestore firestore;
  const MapCreateNest({Key? key, required this.firestore}) : super(key: key);

  @override
  State<MapCreateNest> createState() => _MapCreateNestState();
}

class _MapCreateNestState extends State<MapCreateNest> {
  CameraPosition camPos = CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 270,
    zoom: 16.35,
  );

  SharedPreferencesService? sps;

 late DocumentReference<Map<String, dynamic>> lastId;

  Nest nest = Nest(
    coordinates: GeoPoint(0, 0),
    accuracy: "loading...",
    last_modified: DateTime.now(),
    discover_date: DateTime.now(),
    responsible: null,
    measures: [Measure.note()],
  );


  GoogleMapController? _googleMapController;
  var today = DateTime.now().day;

  Set<Circle> circle = {
    Circle(
      circleId: CircleId("myLocEmpty"),
    )
  };
  final focus = FocusNode();
  Set<Marker> markers = {};
  bool _locOK = false;

  StreamSubscription<Position>? _positionStreamSubscription;
  LocationService location = LocationService.instance;
  AuthService auth = AuthService.instance;

  @override
  void initState() {
    super.initState();
    auth.isUserSignedIn().then((value) {
      if (value == false) {
        Navigator.pushReplacementNamed(context, "/settings");
      }
    });
    location.determinePosition(context, _locOK).then((value) => _locOK);
    lastId = widget.firestore.collection('recent').doc("nest");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      camPos = sps!.defaultLocation;
      _positionStreamSubscription = location.getPositionStream().listen((Position position) {
        if (mounted) {
          nest.accuracy = position.accuracy.toStringAsFixed(2) + "m";
          nest.coordinates = GeoPoint(position.latitude, position.longitude);
          setState(() {
            circle = {
              Circle(
                circleId: CircleId("myLoc"),
                radius: position.accuracy,
                center: LatLng(position.latitude, position.longitude),
                strokeColor: Colors.orange,
              )
            };
          });
          _googleMapController?.animateCamera(
              CameraUpdate.newCameraPosition(CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                bearing: 270,
                zoom: 18.35,
              ))
          );
        }
      });
    });
    _positionStreamSubscription = location.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          circle = {
            Circle(
              circleId: CircleId("myLoc"),
              radius: position.accuracy,
              center: LatLng(position.latitude, position.longitude),
              strokeColor: Colors.orange,
            )
          };
        });
        _googleMapController?.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              bearing: 270,
              zoom: 18.35,
            ))
        );
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _googleMapController?.dispose();
    focus.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        Column(
                children: [
                  Flexible(
                    child: GoogleMap(
                      circles: circle,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      markers: markers,
                      mapType: MapType.satellite,
                      zoomControlsEnabled: false,
                      initialCameraPosition: camPos,
                      onMapCreated: (controller) =>
                      _googleMapController = controller,
                    ),
                  ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "RefreshLocation",
            onPressed: ()  {
                 location.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.best)
                  .then((value) {
                _googleMapController?.animateCamera(
                    CameraUpdate.newCameraPosition(CameraPosition(
                      target: LatLng(value.latitude, value.longitude),
                      bearing: 270,
                      zoom: 20.85,
                    ))).whenComplete(() => setState(() {
                  circle = {
                    Circle(
                      circleId: CircleId("myLoc"),
                      zIndex: -1,
                      radius: value.accuracy,
                      center: LatLng(value.latitude, value.longitude),
                      strokeColor: Colors.orange,
                    )
                  };
                }));
              });
              focus.unfocus();
            },
            child: const Icon(Icons.my_location),
          ),

          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoomIn",
            onPressed: () {
              _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(camPos));
              focus.unfocus();
            },
            child: const Icon(Icons.zoom_out_map),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onLongPress: (){
              lastId.get().then((value) {
                if(value.data() != null) {
                  int? next = int.tryParse(value.data()!['id']);
                  if(next != null) {
                    nest.id = (next + 1).toString();
                  }
                  //reserve the id!?
                  //lastId.set({'id': nest.id});
                }
              nest.species = sps!.defaultSpecies;
              Navigator.pushNamed(context, '/createNest', arguments: nest);
            });
            },
            child: FloatingActionButton(
              heroTag: "addNest",
              onPressed: () {
                Navigator.pushNamed(context, '/createNest', arguments: nest);
              },
              child: const Icon(Icons.add),
            ),
          ),


        ],
      ),
    );
  }
}
