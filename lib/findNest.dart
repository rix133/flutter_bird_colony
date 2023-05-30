import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/buildForm.dart';

class FindNearby extends StatefulWidget {
  const FindNearby({Key? key}) : super(key: key);

  @override
  State<FindNearby> createState() => _FindNearbyState();
}

class _FindNearbyState extends State<FindNearby> {
  List list=[];
  final nestID = TextEditingController();
  @override
  Widget build(BuildContext context) {
    CollectionReference pesa = FirebaseFirestore.instance.collection('2023');
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
            buildForm(context, "enter nest ID", null, nestID,true),
              new ElevatedButton.icon(
                  onPressed: () async {
                    var sihtkoht = nestID.text;
                      var exists = await pesa.doc(sihtkoht).get();
                      if (exists.exists==true) {
                                  Navigator.pushNamed(
                                      context, "/nestManage",
                                      arguments: {
                                        "sihtkoht": sihtkoht,
                                      });
                                  nestID.text="";
                                }
                      else {
                        AlertDialog(
                          title: Text("nest does not exist",
                              style: TextStyle(color: Colors.deepPurpleAccent)
                          ),
                        );
                      }
                  },
                  icon: Icon(
                    Icons.search,
                    color: Colors.black87,
                    size: 45,
                  ),
                  label: Text("Find nest")),
        ]
        ),
      ),
    );
  }
}
