import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/firestoreItem.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

class FSItemMixin {
  // Way to run function on firestoreitems
  Future<UpdateResult> deleteFiresoreItem(FirestoreItem item,
      CollectionReference from, CollectionReference to) async {
    return (to.doc(item.id).get().then((doc) {
      //check if the item is already in deleted collection
      if (doc.exists == false) {
        return to
            .doc(item.id)
            .set(item.toJson())
            .then((value) => from
                .doc(item.id)
                .delete()
                .then((value) => UpdateResult.deleteOK(item: item)))
            .catchError(
                (error) => UpdateResult.error(message: error.toString()));
      } else {
        return to
            .doc('${item.id}_${DateTime.now().toString()}')
            .set(item.toJson())
            .then((value) => from
                .doc(item.id)
                .delete()
                .then((value) => UpdateResult.deleteOK(item: item)))
            .catchError(
                (error) => UpdateResult.error(message: error.toString()));
      }
    }).catchError((error) => UpdateResult.error(message: error.toString())));
  }

  Future<UpdateResult> saveChangeLog(
      FirestoreItem item, CollectionReference to) async {
    return (to
        .doc(item.id)
        .collection("changelog")
        .doc(DateTime.now().toString())
        .set(item.toJson())
        .then((value) => UpdateResult.saveOK(item: item))
        .catchError((error) => UpdateResult.error(message: error.toString())));
  }

  Future<void> downloadExcel(List<FirestoreItem> items, String type) async {
    if (type == "nest") {
      //TODO add eggs as well
    }
    // get all items with headers
    List<TextCellValue> headers = [];
    List<List<CellValue>> data = [];
    if (items.length > 0) {
      for (var item in items) {
        headers.addAll(item.toExcelRowHeader());
        data.addAll(await item.toExcelRows());
      }
      //sort all data by headers so that each row has the same order of cells match by header name
      //first get unique headers
      Set<TextCellValue> uniqueHeaders = headers.toSet();
      //sort the headers
      //List<TextCellValue> sortedHeaders = uniqueHeaders.toList()..sort((a, b) => a.value.compareTo(b.value));

      // align the data rows according to the sorted headers
      List<List<CellValue>> sortedData = [];
      for (var i = 0; i < data.length; i++) {
        List<CellValue> sortedRow = [];
        for (var j = 0; j < uniqueHeaders.length; j++) {
          if (data[i].length > j &&
              headers[i].value == uniqueHeaders.elementAt(j).value) {
            sortedRow.add(data[i][j]);
          } else {
            sortedRow.add(TextCellValue(""));
          }
        }
        sortedData.add(sortedRow);
      }

      //save the file
      await saveAsExcel(sortedData, type);
    } else {
      return null;
    }
  }

  saveAsExcel(List<List<CellValue>> rows, String type) async {
    String fName = type + "_" + DateTime.now().toIso8601String() + ".xlsx";
    Excel excel = Excel.createExcel(); // Create a new Excel file

    Sheet sheet = excel[type]; // Access a sheet
    excel.setDefaultSheet(type);
    //excel.delete("Sheet1"); // Delete the default sheet (Sheet1)

    CellStyle headStyle = CellStyle(backgroundColorHex: "#D3D3D3", bold: true);
    CellStyle bodyStyle = CellStyle(backgroundColorHex: "none", bold: false);
    CellStyle currenctStyle = headStyle;
    for (int i = 0; i < rows.length; i++) {
      if (i != 0) {
        currenctStyle = bodyStyle;
      }
      for (int j = 0; j < rows[i].length; j++) {
        sheet.updateCell(
            CellIndex.indexByColumnRow(rowIndex: i, columnIndex: j), rows[i][j],
            cellStyle: currenctStyle);
      }
    }
    // Auto fit the columns for data
    for (int j = 0; j < rows[1].length; j++) {
      sheet.setColumnAutoFit(j);
    }
    if (!kIsWeb) {
      // If the platform is not web
      final directory = await getTemporaryDirectory();
      final path = directory.path;
      final file = XFile(join(path, fName),
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      List<int>? encodedExcel = excel.save();
      if (encodedExcel != null) {
        File saveFile = File(join(file.path))
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodedExcel);

        await Share.shareXFiles([file], text: 'Sharing $type');
        //delete the file from local storage
        saveFile.delete();
      }
    } else {
      // If the platform is web
      excel.save(fileName: fName);
    }
  }
}
