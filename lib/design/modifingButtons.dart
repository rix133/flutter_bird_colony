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

  Future<void> saveItem(BuildContext superContext,
      {bool validate = true, bool allowOverwrite = false}) async {
    item = widget.getItem();
    List<FirestoreItem> otherFSItems = widget.getOtherItems == null
        ? <FirestoreItem>[]
        : widget.getOtherItems!(); //get other items
    bool doValidate = validate;
    if (validate) {
      ur = item.validate(otherItems: otherFSItems);
      if (!ur.success) {
        showAlertDialog(context, "Validation failed. " + ur.message, saveItem,
            validate: false, btnString: "save anyway");
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
      showAlertDialog(
          context,
          "Item could not be saved." +
              ur.message +
              " Do you want to try to overwrite?",
          saveItem,
          silentOverwrite: true,
          btnString: "Overwrite",
          validate: doValidate);
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
                    context, "Item could not be deleted. " + ur.message, close,
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

  void showAlertDialog(BuildContext context, String message, Function action,
      {bool silentOverwrite = false,
      String btnString = "Retry",
      bool validate = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await action(context,
                  allowOverwrite: silentOverwrite, validate: validate);
            },
            child: Text(btnString, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                        MaterialStateProperty.all(
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

