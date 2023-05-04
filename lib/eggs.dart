import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/buildForm.dart';

class Eggs extends StatefulWidget {
  const Eggs({Key? key}) : super(key: key);

  @override
  State<Eggs> createState() => _EggsState();
}

class _EggsState extends State<Eggs> {
  var signed;
  var username;
  var setChar;
  final weight = new TextEditingController();
  final egg_status = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        signed = false;
      } else {
        print('User is signed in as ' + user.displayName.toString());
        signed = true;
        username = user.displayName.toString();
      }
    });
    final data = ModalRoute.of(context)?.settings.arguments as Map;
    final egg = FirebaseFirestore.instance
        .collection('2023')
        .doc(data["sihtkoht"])
        .collection("egg")
        .doc(data["egg"]);
    egg.get().then((value) {
      weight.text = value.get("mass").toString();
    });
    var future = egg.get();

    return FutureBuilder<DocumentSnapshot>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("loading...");
          }
          egg_status.text = snapshot.data?.get("status") ?? "";
          return Scaffold(
              body: Center(
                  child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RawAutocomplete<Object>(
                  focusNode: _focusNode,
                  onSelected: (selectedString) {
                    print(selectedString);
                  },
                  textEditingController: egg_status,
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextFormField(
                      onTap: () {
                        egg_status.text = "";
                      },
                      textAlign: TextAlign.center,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        labelText: "status",
                        hintText: "enter status",
                        fillColor: Colors.orange,
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: (BorderSide(color: Colors.indigo))),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide(
                            color: Colors.deepOrange,
                            width: 1.5,
                          ),
                        ),
                      ),
                      focusNode: focusNode,
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                        print('You just typed a new entry  $value');
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return [
                      "intact",
                      "predated",
                      "crack",
                      "broken",
                      "missing",
                      "unknown",
                      "small hole",
                      "medium hole",
                      "big hole",
                      "destroyed by human",
                      "drowned",
                      "hatched"
                    ].where((element) {
                      print(element
                          .toString()
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase())
                          .toString());
                      return element
                          .toString()
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Scaffold(
                      body: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option.toString(),
                                textAlign: TextAlign.center,
                              ),
                              textColor: Colors.black,
                              contentPadding: EdgeInsets.all(0),
                              visualDensity: VisualDensity.comfortable,
                              tileColor: Colors.orange[300],
                                onTap: () {
                                  onSelected(option);
                                },
                            );
                          },
                          separatorBuilder: (context, index) => Divider(
                                height: 0,
                              ),
                          itemCount: options.length),
                    );
                  }),
              SizedBox(height: 15),
              buildForm(context, "weight", null, weight, true),
              ElevatedButton.icon(
                  onPressed: () {
                    var status = egg_status.text;
                    var mass =
                        double.tryParse(weight.text.replaceAll(",", "."));
                    egg.update({
                      "mass": mass,
                      "last_modified": DateTime.now(),
                      "responsible": username,
                      "status": status,
                    });
                    egg
                        .collection("changelog")
                        .doc(DateTime.now().toString())
                        .set({
                      "mass": mass,
                      "last_modified": DateTime.now(),
                      "responsible": username,
                      "status": status,
                    });
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.save,
                    color: Colors.black87,
                    size: 45,
                  ),
                  label: Text("save and check")), //save button),
            ],
          )));
        });
  }
}
