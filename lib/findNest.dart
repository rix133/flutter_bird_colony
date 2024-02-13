import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/buildForm.dart';

class FindNest extends StatefulWidget {
  const FindNest({Key? key}) : super(key: key);

  @override
  State<FindNest> createState() => _FindNestState();
}

class _FindNestState extends State<FindNest> {
  CollectionReference pesa = FirebaseFirestore.instance.collection(DateTime.now().year.toString());
  bool enableBtn = true;
  void submitForm(){
    enableBtn = false;
    searchNest(nestID.text);
  }

  void searchNest(String target) async {
      var exists = await pesa.doc(target).get();
      if (exists.exists==true) {
        Navigator.pushNamed(
            context, "/nestManage",
            arguments: {
              "sihtkoht": target,
            });
        nestID.text="";
      }
      else {
        AlertDialog(
          title: Text("nest does not exist",
              style: TextStyle(color: Colors.deepPurpleAccent)
          ),
          content: Text("Please check the nest ID",
              style: TextStyle(color: Colors.deepPurpleAccent)
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                enableBtn = true;
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      }
      enableBtn = true;
    }

  List list=[];
  final nestID = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildForm(context, "enter nest ID", null, nestID,true, searchNest),
              new ElevatedButton.icon(
                  onPressed: enableBtn ? submitForm : null,
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
