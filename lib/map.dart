import 'dart:ui';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';
import 'search.dart' as globals;


class Map extends StatefulWidget {
  const Map({Key? key}) : super(key: key);

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  var today = DateTime.now().toIso8601String().split("T")[0];
  static const kakrarahud = CameraPosition(
    target: LatLng(58.766218, 23.430432),
    bearing: 270,
    zoom: 16.35,
  );

  late GoogleMapController _googleMapController;
  var loc;
  var visible = "";
  var rest1="";
  var rest2="";
  var rest3="";

  CollectionReference pesa = FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  Set<Circle> circle = {
    Circle(
      circleId: CircleId("myLocEmpty"),
    )
  };
  final search = TextEditingController();
  final focus = FocusNode();
  Set<Marker> markers = {};

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    search.dispose();
    focus.dispose();
    _googleMapController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    visible=globals.search;
    search.text=globals.search;
    Stream<Position> loc=Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
        )
    );



    var brackets=visible.contains("[")?visible.split("[").last.split("]").first:"";
    if(brackets!=""){
      rest1=visible.replaceAll("["+brackets+"]", "").trimLeft().trimRight();
    }else{rest1=visible.toString();}

    var parentheses=rest1.contains("(")?rest1.split("(").last.split(")").first:"";
    if(parentheses!=""){
      rest2=rest1.replaceAll("("+parentheses+")", "").trimLeft().trimRight();
    }else{rest2=rest1.toString();}

    var curly=rest2.contains("{")?rest2.split("{").last.split("}").first:"";
    if(curly!=""){
      rest3=rest2.replaceAll("{"+curly+"}", "").trimLeft().trimRight();
    }else{rest3=rest2.toString();}
    List<String> curlymap=curly.split(",");

    Query redMarkerFilter=pesa
        .where("last_modified",
        isLessThanOrEqualTo: DateTime(
            rest3 == "red" ? DateTime.now().year : DateTime.now().year + 1,
            DateTime.now().month,
            DateTime.now().day));
    Stream<QuerySnapshot> _nestsStream=curlymap.first!=""&&curlymap.length<=10?redMarkerFilter.where("id",whereIn: curlymap).snapshots() : pesa.snapshots();

    return Scaffold(
      body: StreamBuilder(
          stream: _nestsStream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            final sharedPreferencesService = Provider.of<SharedPreferencesService>(context);
            if (snapshot.hasData) {
              List<DocumentChange<Object?>> delete=snapshot.data!.docChanges;
              var changes=snapshot.data!.docChanges.where((element) => element.newIndex!=-1).toList();
              delete.where((element) => element.newIndex==-1).forEach((element) {markers.removeWhere((element2) => element2.markerId==MarkerId(element.doc.id));});
              for (var i = 0; i < changes.length; i++) {
                var snap=changes[i].doc;
                var id = snap.id;
                var species=snap.get("species")??"";
                var visibility= false;
                var coords = snap.get("coordinates");
                var colour;
                var name;
                bool speciesBool=species.toLowerCase().contains(parentheses.toLowerCase());
                if (snap.get("last_modified").toDate().toIso8601String().split("T")[0].toString() ==
                    today) {
                  colour = BitmapDescriptor.hueGreen;
                  name = "green";
                } else {
                  name = "red";
                  colour = BitmapDescriptor.hueRed;
                }
                if (visible == "" ||
                    (
                        speciesBool &&
                        (curlymap.first==""?true:curlymap.contains(id))&&
                        (rest3 == ""
                            ? true
                            : (rest3 == id ||
                            (rest3=="today"?(snap.data().toString().contains("discover_date")?snap.get("discover_date").toDate().toIso8601String().split("T")[0].toString()==today:false):false)||
                            rest3==name)))) {
                  visibility=true;
                }
                markers.add(Marker(
                    infoWindow: InfoWindow(
                        title: id,
                        onTap: () => Navigator.pushNamed(context, "/nestManage",
                            arguments: {"sihtkoht": id})),
                    consumeTapEvents: false,
                    visible: visibility,
                    markerId: MarkerId(id),
                    //visible: snapshot.data!.docs[i].get("last_modified").toDate().day==today,
                    icon: BitmapDescriptor.defaultMarkerWithHue(colour),
                    position: LatLng(coords.latitude, coords.longitude)));
/*                for (var i = 0; i <1000; i++){
                  markers.add(
                      Marker(
                        markerId: MarkerId((i+2000).toString()),
                        position: LatLng(58.766525+(i*0.000005),23.4312),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),

                      )
                  );}*/
              }
              return Column(
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
              );
            } else {
              return Text("loading...");
            }
          }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StreamBuilder<Position>(
            stream: loc,
            builder: (context, AsyncSnapshot<Position>  snapshot) {
              if(snapshot.hasData==false){Text("");}
              return StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, snapshot1) {
                  return Column(
                    children: [
                      FloatingActionButton(
                        onPressed: (){
                          _googleMapController.animateCamera(
                              CameraUpdate.newCameraPosition(CameraPosition(
                                target: LatLng(snapshot.data?.latitude??58.766218, snapshot.data?.longitude??23.430432),
                                bearing: snapshot1.hasData?snapshot1.data!.heading??270:270,
                                zoom: 19.85,
                              )));
                        },
                        child: const Icon(Icons.compass_calibration),
                      ),
                      SizedBox(height: 5),
                      FloatingActionButton(
                              onPressed: () {
                                  _googleMapController.animateCamera(
                                      CameraUpdate.newCameraPosition(CameraPosition(
                                        target: LatLng(snapshot.data?.latitude??58.766218, snapshot.data?.longitude??23.430432),
                                        bearing: snapshot1.hasData?snapshot1.data!.heading??270:270,
                                        zoom: 19.85,
                                      )));
                                  if(mounted){
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
                }
              );
            }
          ),

          SizedBox(height: 5),
          FloatingActionButton(
            onPressed: () {
              _googleMapController
                  .animateCamera(CameraUpdate.newCameraPosition(kakrarahud));
              focus.unfocus();
            },
            child: const Icon(Icons.zoom_out_map),
          ),
          SizedBox(height: 5),
          FloatingActionButton(
            isExtended: false,
            onPressed: () {
              _googleMapController
                  .animateCamera(CameraUpdate.newCameraPosition(kakrarahud));
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
                            onEditingComplete: ()async
                            {
                              setState(() {
                              visible = search.text;
                              globals.search = search.text;
                              focus.unfocus();
                              Navigator.pop(context, 'exit');
                            });},
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
            onPressed: () {
              Navigator.pushNamed(context, "/pesa");
            },
            child: const Icon(Icons.add),
          ),


        ],
      ),
    );
  }
}
