import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

Row modifingButtons(BuildContext context, FirestoreItem Function(BuildContext context) getItem, String type, CollectionReference? otherItems, Map? args, String? targetUrl, {bool silentOverwrite = false, bool disabled =false, Function? onSaveOK = null, Function? onDeleteOK = null}){
  UpdateResult ur = UpdateResult(success: false, message: "", type: "empty");
  FirestoreItem item = getItem(context);
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
          onPressed: (disabled || (item.id == null)) ? null : () {
            disabled = true;
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
                          FirestoreItem item = getItem(context);
                          ur = await item.delete(otherItems: otherItems, type: type);
                          if(!ur.success){
                            showDialog(context: context, builder: (_) =>
                                AlertDialog(
                                  contentTextStyle:
                                  TextStyle(color: Colors.black),
                                  titleTextStyle:
                                  TextStyle(color: Colors.red),
                                  title: Text("Error"),
                                  content: Text("Item could not be deleted. " + ur.message),
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
                            //close delete confirmation dialog
                            onDeleteOK?.call();
                            Navigator.pop(context);
                            if(args != null && targetUrl != null){
                              //close the current page and the page before and go to the target page
                              //this basically updates the page before
                              Navigator.pop(context);
                              Navigator.popAndPushNamed(context, targetUrl, arguments: args);
                            } else {
                              //close the page and go to page before (not updating the page before)
                              Navigator.pop(context);
                            }
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
          onPressed: disabled ? null : () async {
            disabled = true;
            FirestoreItem item = getItem(context);
            item.responsible = sps.userName;
            ur = await item.save(otherItems: otherItems, allowOverwrite: silentOverwrite, type: type);
            if(!ur.success){
              showDialog(context: context, builder: (_) =>
                  AlertDialog(
                    title: Text("Error"),
                    contentTextStyle:
                    TextStyle(color: Colors.black),
                    titleTextStyle:
                    TextStyle(color: Colors.red),
                    content: Text("Item could not be saved." + ur.message + " Do you want to try to overwrite?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async{
                          ur = await item.save(otherItems: otherItems, allowOverwrite: true, type: type);
                          if(!ur.success){
                            Navigator.pop(context);
                            showDialog(context: context, builder: (_) =>
                                AlertDialog(
                                  title: Text("Error"),
                                  contentTextStyle:
                                  TextStyle(color: Colors.black),
                                  titleTextStyle:
                                  TextStyle(color: Colors.red),
                                  content: Text("Item could not be overwritten. "+ ur.message),
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
                            onSaveOK?.call();
                            Navigator.pop(context);
                            if(args != null && targetUrl != null){
                              Navigator.pop(context);
                              Navigator.popAndPushNamed(context, targetUrl, arguments: args);
                            } else {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text('Overwrite', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ));
            }
            else{
              onSaveOK?.call();
              if(args != null && targetUrl != null){
                Navigator.pop(context);
                Navigator.popAndPushNamed(context, targetUrl, arguments: args);
              } else {
                Navigator.pop(context);
              }
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