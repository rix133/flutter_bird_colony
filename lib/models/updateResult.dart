import 'package:kakrarahu/models/firestore_item.dart';


class UpdateResult {
  bool success = false;
  String type = "save";
  String message = "";
  FirestoreItem? item;

  UpdateResult({required this.success, required this.message, required this.type, this.item});

  UpdateResult.saveOK({required this.item}){
    UpdateResult( success: true, message: "Saved", type: "save", item: item);
  }
  UpdateResult.deleteOK({required this.item}){
    UpdateResult( success: true, message: "Deleted", type: "delete", item: item);
  }
  UpdateResult.error({required this.message}){
    UpdateResult( success: false, message: message, type: "error");
  }
}