import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';

Row modifingButtons(BuildContext context, CollectionReference items, FirestoreItem item, SharedPreferencesService sps){
  bool isButtonClicked = false;

  return(Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      new ElevatedButton.icon(
          style: ButtonStyle(
              backgroundColor:
              MaterialStateProperty.all(
                  Colors.red[900])),
          onPressed: isButtonClicked ? null : () {
            isButtonClicked = true;
            showDialog<String>(
              barrierColor: Colors.black,
              context: context,
              builder: (BuildContext context) =>
                  AlertDialog(
                    contentTextStyle:
                    TextStyle(color: Colors.black),
                    titleTextStyle:
                    TextStyle(color: Colors.red),
                    title: const Text("Removing item"),
                    content: const Text(
                        'Are you sure you want to delete this item?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(
                            context, 'Cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          var time = DateTime.now();
                          var kust =
                          items.doc(item.name);
                          kust
                              .collection("changelog")
                              .get()
                              .then((value) => value.docs
                              .forEach((element) {
                            element.reference
                                .update({
                              "deleted": time
                            });
                          }));
                          kust.delete();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          },
          icon: Icon(
            Icons.delete,
            size: 45,
          ),
          label: Text("delete")),
      ElevatedButton.icon(
          onPressed: isButtonClicked ? null : () async {
            isButtonClicked = true;
            item.responsible = sps.userName;
            if(item.id==null){
              items.add(item.toJson()).then((value) => items.doc(value.id).collection("changelog").doc(DateTime.now().toString()).set({"created":DateTime.now()}));
            Navigator.pop(context);
            } else {
            items.doc(item.id).update(item.toJson()).then((value) => items.doc(item.id).update({"last_modified":DateTime.now()}));
            Navigator.pop(context);
            }
          },
          icon: Icon(
            Icons.save,
            color: Colors.black87,
            size: 45,
          ),
          label: Text("save")),//save button
    ],
  ));
}