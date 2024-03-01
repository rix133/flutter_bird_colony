import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/buildForm.dart';

import 'models/nest.dart';

class FindNest extends StatefulWidget {
  final FirebaseFirestore firestore;
  const FindNest({Key? key, required this.firestore})  : super(key: key);

  @override
  State<FindNest> createState() => _FindNestState();
}

class _FindNestState extends State<FindNest> {
  CollectionReference? nests;
  bool enableBtn = true;
  void submitForm(){
    setState(() {
      enableBtn = false;
    });
    searchNest(nestID.text);
  }

  @override
  void initState() {
    super.initState();
    nests = widget.firestore.collection(DateTime.now().year.toString());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void searchNest(String target) async {
    if(target.isEmpty){
      setState(() {
        enableBtn = true;
      });
      return;
    }
    if(nests == null){
      setState(() {
        enableBtn = true;
      });
      return;
    }
    DocumentSnapshot data = await nests!.doc(target).get();
    if (data.exists) {
      Navigator.pushNamed(
          context, "/nestManage",
          arguments: {
            "nest": Nest.fromDocSnapshot(data),
          });
      nestID.text="";
    }
    else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // Start the timer when the dialog is built
          Future.delayed(Duration(seconds: 2), () {
            Navigator.of(context).pop();
          });
          return AlertDialog(
            title: Text("Nest ${nestID.text} does not exist",
                style: TextStyle(color: Colors.red)
            ),
            content: Text("Please check the nest ID",
                style: TextStyle(color: Colors.black)
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {

                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
    setState(() {
      enableBtn = true;
    });
  }

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
