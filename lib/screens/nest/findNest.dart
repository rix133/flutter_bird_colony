import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/buildForm.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bird_colony/utils/year.dart';

import '../../services/sharedPreferencesService.dart';

class FindNest extends StatefulWidget {
  final FirebaseFirestore firestore;
  const FindNest({Key? key, required this.firestore})  : super(key: key);

  @override
  State<FindNest> createState() => _FindNestState();
}

class _FindNestState extends State<FindNest> {
  CollectionReference? nests;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _widgetFocusNode = FocusNode();
  SharedPreferencesService? sps;
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
    nests = widget.firestore.collection(yearToNestCollectionName(DateTime.now().year));
    _widgetFocusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      nests = widget.firestore
          .collection(yearToNestCollectionName(sps?.selectedYear ?? DateTime.now().year));
      setState(() {});
    });
  }

  void _onFocusChange() {
    if (_widgetFocusNode.hasFocus) {
      setState(() {
        enableBtn = true;
      });
    }
  }

  @override
  void dispose() {
    _widgetFocusNode.removeListener(_onFocusChange);
    _widgetFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void resetButtonState() {
    setState(() {
      enableBtn = true;
    });
  }

  void searchNest(String target) async {
    if (target.isEmpty || nests == null) {
      setState(() {
        enableBtn = true;
      });
      return;
    }
    DocumentSnapshot data = await nests!.doc(target).get();
    if (data.exists) {
      Navigator.pushNamed(
          context, '/editNest',
          arguments: {
            "nest": Nest.fromDocSnapshot(data),
          });
      nestID.text="";
      enableBtn = true;
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
    return Focus(
        focusNode: _widgetFocusNode,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
            appBar: (sps?.showAppBar ?? true)
                ? AppBar(
                    title: Text('Search nests'),
                  )
                : null,
            body: SafeArea(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildForm(context, "enter nest ID", null, nestID,true, searchNest, _focusNode),
              new ElevatedButton.icon(
                      key: Key('findNestButton'),
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
            )));
  }
}
