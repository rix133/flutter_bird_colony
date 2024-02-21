import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/firestoreItem.dart';
import 'package:kakrarahu/models/updateResult.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

import 'egg.dart';

class FSItemMixin {
  // Workaround Way to run functions on firestoreitems
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

  Future<List<List<CellValue>>> createSortedData(List<FirestoreItem> items,
      {DateTime? start, DateTime? end}) async {
    if (start == null) {
      start = DateTime.now();
    }
    if (end == null) {
      end = DateTime(1900);
    }
    DateTime? current;
    List<List<TextCellValue>> headers = [];
    List<List<CellValue>> data = [];
    if (items.length > 0) {
      for (var item in items) {
        headers.add(item.toExcelRowHeader());
        current = item.last_modified;
        if (current != null && current.isAfter(end!)) {
          end = current;
        }
        if (current != null && current.isBefore(start!)) {
          start = current;
        }
        data.addAll(await item.toExcelRows());
      }
      Set<TextCellValue> uniqueHeaders = headers.expand((e) => e).toSet();
      List<List<CellValue>> sortedData = [uniqueHeaders.toList()];
      for (var i = 0; i < data.length; i++) {
        Map<String, CellValue> rowMap =
            Map.fromIterables(headers[i].map((h) => h.value), data[i]);
        List<CellValue> sortedRow = uniqueHeaders
            .map((h) => rowMap.containsKey(h.value)
                ? rowMap[h.value]!
                : TextCellValue(""))
            .toList();
        sortedData.add(sortedRow);
      }
      return sortedData;
    } else {
      return [];
    }
  }

  Future<void> downloadExcel(List<FirestoreItem> items, String type,
      {DateTime? start, DateTime? end}) async {
    List<List<CellValue>> sheetData =
        await createSortedData(items, start: start, end: end);
    List<List<List<CellValue>>> sheets = [sheetData];
    List<String> types = [type];

    if (type == "nest") {
      if (start != null && end != null) {
        Timestamp startTimestamp = Timestamp.fromDate(start);
        Timestamp endTimestamp = Timestamp.fromDate(end);
        //get all eggs between start and end
        QuerySnapshot eggs = await FirebaseFirestore.instance
            .collectionGroup("egg")
            .where("discover_date", isGreaterThanOrEqualTo: startTimestamp)
            .where("discover_date", isLessThanOrEqualTo: endTimestamp)
            .get();
        if (eggs.docs.isNotEmpty) {
          List<FirestoreItem> eggItems =
              eggs.docs.map((e) => Egg.fromDocSnapshot(e)).toList();
          List<List<CellValue>> eggSheetData =
              await createSortedData(eggItems, start: start, end: end);
          sheets.add(eggSheetData);
          types.add("egg");
        }
      }
    }
    if (sheets.isNotEmpty) {
      return await saveAsExcel(sheets, types);
    } else {
      return null;
    }
  }

  saveAsExcel(List<List<List<CellValue>>> sheets, List<String> types) async {
    String fName =
        types.join("_") + "_" + DateTime.now().toIso8601String() + ".xlsx";
    Excel excel = Excel.createExcel(); // Create a new Excel file
    for (int i = 0; i < sheets.length; i++) {
      String type = types[i];
      List<List<CellValue>> rows = sheets[i];
      Sheet sheet = excel[type]; // Access a sheet
      //excel.delete("Sheet1"); // Delete the default sheet (Sheet1)

      CellStyle headStyle =
          CellStyle(backgroundColorHex: "#D3D3D3", bold: true);
      CellStyle bodyStyle = CellStyle(backgroundColorHex: "none", bold: false);
      CellStyle currenctStyle = headStyle;
      for (int i = 0; i < rows.length; i++) {
        if (i != 0) {
          currenctStyle = bodyStyle;
        }
        for (int j = 0; j < rows[i].length; j++) {
          sheet.updateCell(
              CellIndex.indexByColumnRow(rowIndex: i, columnIndex: j),
              rows[i][j],
              cellStyle: currenctStyle);
        }
      }
      // Auto fit the columns for data
      for (int j = 0; j < rows[1].length; j++) {
        sheet.setColumnAutoFit(j);
      }
    }
    excel.setDefaultSheet(types[0]);

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

        await Share.shareXFiles([file],
            text:
                'Sharing ${types.join(", ")} file from Kakrarahu app. Downloaded on ${DateTime.now().toIso8601String()}');
        //delete the file from local storage
        saveFile.delete();
      }
    } else {
      // If the platform is web
      excel.save(fileName: fName);
    }
  }
}
