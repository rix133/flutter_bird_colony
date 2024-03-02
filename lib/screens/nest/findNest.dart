import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/design/buildForm.dart';

import 'package:kakrarahu/models/firestore/nest.dart';

class FindNest extends StatefulWidget {
  final FirebaseFirestore firestore;
  const FindNest({Key? key, required this.firestore})  : super(key: key);

  @override
  State<FindNest> createState() => _FindNestState();
}

class _FindNestState extends State<FindNest> {
  CollectionReference? nests;
  final FocusNode _focusNode = FocusNode();
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
    _focusNode.dispose();
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
      // Dismiss the keyboard
      setState(() {
        enableBtn = true;
        _focusNode.unfocus();
      });
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nest ${nestID.text} does not exist"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Wait for the SnackBar to close before requesting focus
      Future.delayed(Duration(seconds: 2), () {
        _focusNode.requestFocus();
      });
    }

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
              buildForm(context, "enter nest ID", null, nestID,true, searchNest, _focusNode),
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
