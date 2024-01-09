import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapForCreate extends StatefulWidget {
  const MapForCreate({Key? key}) : super(key: key);

  @override
  State<MapForCreate> createState() => _MapForCreateState();
}

class _MapForCreateState extends State<MapForCreate> {
  String get _year => DateTime.now().year.toString();
  static const kakrarahud = CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 270,
    zoom: 16.35,
  );


  late GoogleMapController _googleMapController;
  var today = DateTime.now().day;
  var visible = "";
  var rest1="";
  var rest2="";
  late CollectionReference pesa;
  Set<Circle> circle = {
    Circle(
      circleId: CircleId("myLocEmpty"),
    )
  };
  final search = TextEditingController();
  final focus = FocusNode();
  Set<Marker> markers = {};

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    pesa = FirebaseFirestore.instance.collection(_year);
    super.initState();
    _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
        )
    ).listen((Position position) {
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
        _googleMapController.animateCamera(
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
    _googleMapController.dispose();
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
                      initialCameraPosition: kakrarahud,
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
              Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.best)
                  .then((value) {
                _googleMapController.animateCamera(
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
              _googleMapController
                  .animateCamera(CameraUpdate.newCameraPosition(kakrarahud));
              focus.unfocus();
            },
            child: const Icon(Icons.zoom_out_map),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onLongPress: (){
              FirebaseFirestore.instance.collection('recent').doc("kalakas").get().then((value) => Navigator.pushNamed(context, "/pesa",
                  arguments: {
                    "nestid": value.get("nestid"),
                    "species":"Common Gull"
                  }));
            },
            child: FloatingActionButton(
              heroTag: "addNest",
              onPressed: () {
                Navigator.pushNamed(context, "/pesa");
              },
              child: const Icon(Icons.add),
            ),
          ),


        ],
      ),
    );
  }
}
