import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestore/firestoreItem.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'package:kakrarahu/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';


class ModifyingButtons extends StatefulWidget {
  final BuildContext context;
  final Function setState;
  final FirebaseFirestore firestore;
  final FirestoreItem Function() getItem;
  final String type;
  final CollectionReference? otherItems;
  final bool silentOverwrite;
  final Function? onSaveOK;
  final Function? onDeleteOK;

  ModifyingButtons({
    required this.firestore,
    required this.context,
    required this.setState,
    required this.getItem,
    required this.type,
    required this.otherItems,
    this.silentOverwrite = false,
    this.onSaveOK,
    this.onDeleteOK,
  });

  @override
  _ModifyingButtonsState createState() => _ModifyingButtonsState();
}

class _ModifyingButtonsState extends State<ModifyingButtons> {
  UpdateResult ur = UpdateResult(success: false, message: "", type: "empty");
  late FirestoreItem item;
  bool _isLoading = false;
  SharedPreferencesService? sps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
    });
  }

  Stack getButtons(BuildContext superContext, String type, CollectionReference? otherItems, {bool silentOverwrite = false, Function? onSaveOK = null, Function? onDeleteOK = null}){
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
                      item = widget.getItem();
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
                                    Navigator.pop(context);
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    ur = await item.delete(widget.firestore, otherItems: otherItems, type: type);
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
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      //close the item page and go back where it was opened from
                                      if(onDeleteOK != null){
                                        onDeleteOK();
                                      } else{
                                        Navigator.pop(superContext);
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
                    onPressed:  () async {
                      item = widget.getItem();
                      setState(() {
                        _isLoading = true;
                      });
                      item.responsible = sps?.userName ?? item.responsible;
                      ur = await item.save(widget.firestore, otherItems: otherItems, allowOverwrite: silentOverwrite, type: type);
                      if(!ur.success){
                        setState(() {
                          _isLoading = false;
                        });
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
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    ur = await item.save(widget.firestore, otherItems: otherItems, allowOverwrite: true, type: type);
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
                                      if(onSaveOK != null){
                                        onSaveOK();
                                      } else{
                                        Navigator.pop(superContext);
                                      }
                                    }
                                  },
                                  child: const Text('Overwrite', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ));
                      }
                      else{
                        _isLoading = false;
                        if(onSaveOK != null){
                          onSaveOK();
                        } else{
                          Navigator.pop(superContext);
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
            ),
          ),
        ),
        if (_isLoading)
          Center(child: CircularProgressIndicator()), // Show loading indicator when loading
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    item = widget.getItem();
    return getButtons(widget.context, widget.type, widget.otherItems, silentOverwrite: widget.silentOverwrite, onSaveOK: widget.onSaveOK, onDeleteOK: widget.onDeleteOK);
  }
}

