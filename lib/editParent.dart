import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/species.dart';

class EditParent extends StatefulWidget {
  const EditParent({Key? key}) : super(key: key);

  @override
  State<EditParent> createState() => _EditParentState();
}

class _EditParentState extends State<EditParent> {
  TextEditingController band_id_letters = TextEditingController();
  TextEditingController band_id_numbers = TextEditingController();
  TextEditingController color_bandCtrl = TextEditingController();
  TextEditingController nestID = TextEditingController();
  TextEditingController eggNr = TextEditingController();
  TextEditingController species = TextEditingController();
  TextEditingController age = TextEditingController();
  FocusNode _focusNode = FocusNode();
  String get _year => DateTime.now().year.toString();

  static String _displayStringForOption(SpeciesList option) => option.english;
  var username;
  var uid;

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        username = user.displayName.toString();
        if (user.uid != uid) {
          print(user.uid);
          setState(() {
            uid = user.uid;
          });
        }
      }
    });
    var map = ModalRoute.of(context)?.settings.arguments as Map;
    species.text = map["species"] ?? "";
    eggNr.text = map["muna_nr"] ?? "";
    nestID.text = map["pesa"] ?? "";
    age.text = map["age"] ?? "";


    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 50, 10, 15),
            child: Column(
              children: [Text("Edit bird")]
            ),
          ),
        ),
      ),
    );
  }
}
