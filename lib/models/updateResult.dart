import 'package:kakrarahu/models/firestore_item.dart';


class UpdateResult {
  bool success = false;
  String type = "save";
  String message = "";
  FirestoreItem? item;

  UpdateResult({required this.success, required this.message, required this.type, this.item});

  UpdateResult.saveOK({required this.item})
      : success = true,
        message = "Saved",
        type = "save";

  UpdateResult.deleteOK({required this.item})
      : success = true,
        message = "Deleted",
        type = "delete";

  UpdateResult.error({required this.message})
      : success = false,
         type = "error";
}