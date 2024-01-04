import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';




void main(){
  runApp(NestsNearby());
}




class NestsNearby extends StatefulWidget {
  const NestsNearby({Key? key}) : super(key: key);



  @override
  _NestsNearbyState createState() => _NestsNearbyState();
}
class _NestsNearbyState extends State<NestsNearby>{
  String  get _year  => DateTime.now().year.toString();
  final int  _today = DateTime.now().day;
  late Stream<QuerySnapshot> _nestsStream;
  late CollectionReference pesa;


  @override
  void initState() {
    super.initState();
    pesa = FirebaseFirestore.instance.collection(_year);
    _nestsStream = FirebaseFirestore.instance
        .collection(_year)
        .where("last_modified",
        isLessThanOrEqualTo: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day)).snapshots();
  }



  @override
  Widget build(BuildContext context) {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 15,
    );
    var asukoht;

    final Stream loc=Geolocator.getPositionStream(locationSettings: locationSettings);




    TextStyle myStyle=TextStyle(color: Colors.black);
    return Scaffold(
      body: Center(
        child:Container(
        padding: EdgeInsets.fromLTRB(1, 50, 1, 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[


            StreamBuilder<QuerySnapshot>(
              stream: _nestsStream,
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading");
                }
                  return StreamBuilder(
                      stream: loc,
                      builder: (context, snapshot1) {
                        if(snapshot1.hasData==false){
                          return Text("loading...");
                        }
                        asukoht = snapshot1.data;
                        var latitude=asukoht.latitude;
                        var longitude=asukoht.longitude;
                        var map = [];
                        void addItem([id, distance,species,isChecked]) {
                          if (distance != null && id != null) {
                            map.add({"id": id, "distance": distance,"species":species,"isChecked":isChecked});
                          }
                        }


                        for (var i = 0; i < snapshot.data!.docs.length; i++) {
                          var id = snapshot.data!.docs[i].id;
                          var coords = snapshot.data!.docs[i].get(
                              "coordinates");
                          var isChecked;
                          if(snapshot.data!.docs[i].get("last_modified").toDate().day == _today){
                            isChecked=Colors.green;
                          }else{isChecked=Colors.red[900];}

                          var distance = Geolocator.distanceBetween(coords
                              .latitude, coords.longitude, latitude, longitude);

                          try {
                            addItem(id, distance,
                                snapshot.data!.docs[i].get(
                                    "species"),isChecked);
                          } catch (e) {}
                        }
/*
                        for (var i = 0; i < 1000; i++) {
                          print("say hi "+i.toString());
                          var id = (i+1000).toString();
                          var isChecked;
                          isChecked=Colors.green;

                          var distance = Geolocator.distanceBetween(58.766525+(i*0.000005),23.4312, latitude, longitude);

                          try {
                            addItem(id, distance,
                                "liik",isChecked);
                          } catch (e, s) {}
                        }
*/


                        map.sort((m1, m2) {
                          var r = m1["distance"].compareTo(m2["distance"]);
                          if (r != 0) return r;
                          return m1["id"].compareTo(m2["id"]);
                        });


                        return Flexible(child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: map.length.clamp(0, 25),
                            itemBuilder: (BuildContext context, int index) {
                              return GestureDetector(
                                onTap: () => {},
                                child: Card(
                                  color: map[index]["isChecked"],
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      ListTile(
                                        leading: Text((index + 1).toString(),
                                          style: myStyle,),
                                        title: Text(
                                          map[index]["id"].toString(),
                                          style: TextStyle(
                                              color: Colors.black),),
                                        subtitle:
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:[
                                            Text(map[index]["species"].toString(),
                                                style: myStyle),
                                            Text(
                                                map[index]["distance"].toStringAsFixed(2)+"m",
                                                style: myStyle),
                                          ]
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .end,
                                        children: <Widget>[
                                          TextButton(
                                            child: const Text('Change data',
                                              style: TextStyle(
                                                  color: Colors.indigo),),
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, "/nestManage",arguments: {
                                                "sihtkoht": map[index]["id"].toString(),
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            child: const Text('Checked',
                                              style: TextStyle(
                                                  color: Colors.indigo),),
                                            onPressed: () {
                                              pesa.doc(map[index]["id"]).update({"last_modified":DateTime.now()});
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                        ),);
                      });


              }
            ),
          ],
        ),
        )
      ),
      /*floatingActionButton: FloatingActionButton(
        onPressed:()=> Navigator.pushNamed(context, "/map"),
        child: const Icon(Icons.map_outlined),
        backgroundColor: Colors.white,
      ),*/
    );
  }
}
