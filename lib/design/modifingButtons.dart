import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestoreItem.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

Stack modifingButtons(BuildContext context, Function setState, FirestoreItem Function(BuildContext context) getItem, String type, CollectionReference? otherItems, {bool silentOverwrite = false, Function? onSaveOK = null, Function? onDeleteOK = null}){
  UpdateResult ur = UpdateResult(success: false, message: "", type: "empty");
  FirestoreItem item = getItem(context);
  final sps = Provider.of<SharedPreferencesService>(context, listen: false);
  bool _isLoading = false;
  //if(onSaveOK == null) onSaveOK = (){Navigator.pop(context);};
  //if(onDeleteOK == null) onDeleteOK = (){Navigator.pop(context);};
  return Stack(
      children: [
      Opacity(
      opacity: _isLoading ? 0.3 : 1, // Dim the UI when loading
      child: AbsorbPointer(
      absorbing: _isLoading, // Disable interaction when loading
      child:Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
       ElevatedButton.icon(
          style: ButtonStyle(
              backgroundColor:
              MaterialStateProperty.all(
                  Colors.red[900])),
          onPressed: (item.id == null) ? null : () {
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
                          setState(() {
                            _isLoading = true;
                          });
                          FirestoreItem item = getItem(context);
                          ur = await item.delete(otherItems: otherItems, type: type);
                          if(!ur.success){
                            setState(() {
                              _isLoading = false;
                            });
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
                              _isLoading = false;
                            //close delete confirmation dialog
                             Navigator.pop(context);
                            onDeleteOK?.call();
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
          onPressed:  () async {
            setState(() {
              _isLoading = true;
            });
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
                            setState(() {
                              _isLoading = false;
                            });
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
                            _isLoading = false;
                            Navigator.pop(context);
                            onSaveOK?.call();
                          }
                        },
                        child: const Text('Overwrite', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ));
            }
            else{
              _isLoading = false;
              onSaveOK?.call();
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
      ),
      ),
      ),
        if (_isLoading)
          Center(child: CircularProgressIndicator()), // Show loading indicator when loading
      ],
  );
}