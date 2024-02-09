import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

Row modifingButtons(BuildContext context, FirestoreItem Function() getItem, String type, CollectionReference? otherItems){
  bool isButtonClicked = false;
  FirestoreItem item = getItem();
  final sps = Provider.of<SharedPreferencesService>(context, listen: false);
  return(Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
       ElevatedButton.icon(
          style: ButtonStyle(
              backgroundColor:
              MaterialStateProperty.all(
                  Colors.red[900])),
          onPressed: (isButtonClicked || (item.id == null)) ? null : () {
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
                        onPressed: () async {
                          FirestoreItem item = getItem();
                          isButtonClicked = await item.delete(otherItems: otherItems, type: type);
                          if(!isButtonClicked){
                            showDialog(context: context, builder: (_) =>
                                AlertDialog(
                                  contentTextStyle:
                                  TextStyle(color: Colors.black),
                                  titleTextStyle:
                                  TextStyle(color: Colors.red),
                                  title: Text("Error"),
                                  content: Text("Item could not be deleted"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ));
                          }
                          else{
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }

                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
            FirestoreItem item = getItem();
            item.responsible = sps.userName;
            isButtonClicked = await item.save(otherItems: otherItems, allowOverwrite: false, type: type);
            if(!isButtonClicked){
              showDialog(context: context, builder: (_) =>
                  AlertDialog(
                    title: Text("Error"),
                    contentTextStyle:
                    TextStyle(color: Colors.black),
                    titleTextStyle:
                    TextStyle(color: Colors.red),
                    content: Text("Item could not be saved. Possibly id already exists or is empty. Do you want to try to overwrite?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async{
                          Navigator.pop(context);
                          isButtonClicked = await item.save(otherItems: otherItems, allowOverwrite: true, type: type);
                          if(!isButtonClicked){
                            showDialog(context: context, builder: (_) =>
                                AlertDialog(
                                  title: Text("Error"),
                                  contentTextStyle:
                                  TextStyle(color: Colors.black),
                                  titleTextStyle:
                                  TextStyle(color: Colors.red),
                                  content: Text("Item could not be overwritten."),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ));
                          }
                          else{
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Overwrite', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ));
            }
            else{
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