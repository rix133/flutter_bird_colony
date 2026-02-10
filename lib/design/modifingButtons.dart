import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';


class ModifyingButtons extends StatefulWidget {
  final BuildContext context;
  final Function setState;
  final FirebaseFirestore firestore;
  final FirestoreItem Function() getItem;
  final String type;
  final CollectionReference? otherItems;
  final List<FirestoreItem> Function()? getOtherItems;
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
    this.getOtherItems,
    this.silentOverwrite = false,
    this.onSaveOK,
    this.onDeleteOK,
  });

  @override
  _ModifyingButtonsState createState() => _ModifyingButtonsState();
}

class _ModifyingButtonsState extends State<ModifyingButtons> {
  UpdateResult ur = UpdateResult.error(message: "uninitialized");
  List<UpdateResult> urs = [];
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

  Future<void> saveItem(BuildContext superContext,
      {bool validate = true, bool allowOverwrite = false}) async {
    bool dialogResult = false;
    item = widget.getItem();
    List<FirestoreItem> otherFSItems = widget.getOtherItems == null
        ? <FirestoreItem>[]
        : widget.getOtherItems!(); //get other items
    if (validate) {
      urs = item.validate(sps, otherItems: otherFSItems);
      if (urs.isNotEmpty) {
        dialogResult = await showAlertDialog(
            superContext, "Validation failed", urs,
            btnString: "save anyway");
        if (dialogResult) {
          await saveItem(superContext,
              validate: false, allowOverwrite: allowOverwrite);
          return;
        }
        return;
      }
    }
    setState(() {
      _isLoading = true;
    });
    item.responsible = sps?.userName ?? item.responsible;
    ur = await item.save(widget.firestore,
        otherItems: widget.otherItems,
        allowOverwrite: allowOverwrite,
        type: widget.type);
    if (!ur.success) {
      setState(() {
        _isLoading = false;
      });
      dialogResult = await showAlertDialog(superContext,
          "Item could not be saved. Do you want to try to overwrite?", [ur],
          btnString: "Overwrite");
      if (dialogResult) {
        saveItem(superContext, validate: false, allowOverwrite: true);
      }
    } else {
      _isLoading = false;
      if (widget.onSaveOK != null) {
        widget.onSaveOK!();
      } else {
        Navigator.pop(superContext);
      }
    }
  }

  close(BuildContext context, {bool allowOverwrite = false}) {
    Navigator.pop(context);
  }

  Future<void> deleteItem(BuildContext superContext,
      {bool validate = true, bool allowOverwrite = false}) async {
    item = widget.getItem();
    item.responsible = sps?.userName ?? item.responsible;

    showDialog<String>(
      barrierColor: Colors.black,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        contentTextStyle: TextStyle(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.red),
        title: const Text("Removing item"),
        content: const Text('Are you sure you want to delete this item?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              ur = await item.delete(widget.firestore,
                  otherItems: widget.otherItems, type: widget.type);
              if (!ur.success) {
                setState(() {
                  _isLoading = false;
                });
                showAlertDialog(
                    superContext, "Item could not be deleted.", [ur],
                    btnString: "OK");
              } else {
                setState(() {
                  _isLoading = false;
                });
                if (widget.onDeleteOK != null) {
                  widget.onDeleteOK!();
                } else {
                  Navigator.pop(superContext);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> showAlertDialog(
      BuildContext context, String message, List<UpdateResult> errors,
      {String btnString = "Retry"}) async {
    int errCount = errors.length;
    String mainMessage =
        errCount == 1 ? message : message + " ($errCount errors)";
    bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              backgroundColor: Colors.black87,
              titleTextStyle: TextStyle(color: Colors.red),
              title: Text("Problem(s)"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(mainMessage, style: TextStyle(color: Colors.redAccent)),
                ...errors.map((e) => Text(e.message)).toList(),
              ]),
              actions: <Widget>[
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(btnString, style: TextStyle(color: Colors.red)),
                ),
              ],
            ));
    return result ?? false;
  }

  Stack getButtons(
      BuildContext superContext, String type, CollectionReference? otherItems,
      {bool silentOverwrite = false,
      Function? onSaveOK = null,
      Function? onDeleteOK = null}) {
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
                    key: Key("deleteButton"),
                    style: ButtonStyle(
                        backgroundColor:
                        WidgetStateProperty.all(
                            Colors.red[900])),
                    onPressed: (item.id == null)
                        ? null
                        : () => deleteItem(superContext),
                    icon: Icon(
                      Icons.delete,
                      size: 45,
                    ),
                    label: Text("delete")),
                ElevatedButton.icon(
                    key: Key("saveButton"),
                    onPressed: () =>
                        saveItem(superContext, allowOverwrite: silentOverwrite),
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
    return getButtons(widget.context, widget.type, widget.otherItems,
        silentOverwrite: widget.silentOverwrite,
        onSaveOK: widget.onSaveOK,
        onDeleteOK: widget.onDeleteOK);
  }
}


