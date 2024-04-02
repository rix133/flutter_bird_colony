import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'firestore/bird.dart';
import 'firestore/egg.dart';
import 'firestore/nest.dart';

class FSItemMixin {
  // Workaround Way to run functions on firestoreitems
  Future<UpdateResult> deleteFiresoreItem(
      FirestoreItem item, CollectionReference from) async {
    String deletedTime = DateTime.now().toString();
    return from
        .doc(item.id)
        .collection("changelog")
        .doc("deleted_$deletedTime")
        .set(item.toJson())
        .then((value) => from
            .doc(item.id)
            .delete()
            .then((value) => UpdateResult.deleteOK(item: item)))
        .catchError((error) => UpdateResult.error(message: error.toString()));
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

  Future<Map<String, dynamic>> createSortedData(List<FirestoreItem> items) async {
    DateTime? start;
    DateTime? end;
    List<List<TextCellValue>> headers = [];
    List<List<CellValue>> data = [];
    List<List<CellValue>> itemRows = [];
    if (items.length > 0) {
      for (var item in items) {
        DateTime? last = item.last_modified;
        DateTime first = item.created_date;
        if (start == null || first.isBefore(start)) {
          start = first;
        }
        if (end == null || (last != null && last.isAfter(end))) {
          end = last;
        }
        itemRows = await item.toExcelRows();
        //ensure data and headers have the same length
        for(var i = 0; i < itemRows.length; i++){
          headers.add(item.toExcelRowHeader());
        }
        data.addAll(itemRows);
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
      return {'start': start, 'end': end, 'sortedData': sortedData};
    } else {
      return {'start': null, 'end': null, 'sortedData': []};
    }
  }

  Future<List<List<List<CellValue>>>?> downloadChangeLog(
      Future<List<FirestoreItem>> items,
      String type,
      FirebaseFirestore firestore,
      {DateTime? start,
      bool test = false}) async {
    if (type == "nest") {
      List<String> types = ["nest"];
      List<Nest> nests = await items as List<Nest>;

      List<List<List<CellValue>>>? nestLog =
          await downloadExcel(nests, type, firestore, start: start, test: true);
      if (nestLog != null) {
        Nest n = nests.first;
        List<Egg> eggs = await n.eggs(firestore);
        for (Egg e in eggs) {
          List<List<List<CellValue>>>? eggLog = await downloadExcel(
              [e], e.itemName, firestore,
              start: start, test: true);
          if (eggLog != null) {
            nestLog.addAll(eggLog);
            types.add(e.itemName);
          }
        }
        if (!test) {
          return await saveAsExcel(nestLog, types);
        } else {
          return nestLog;
        }
      } else {
        return null;
      }
    } else {
      return downloadExcel(await items, type, firestore,
          start: start, test: test);
    }
  }

  Future<List<List<List<CellValue>>>?> downloadExcel(
      List<FirestoreItem> items, String type, FirebaseFirestore firestore,
      {DateTime? start, bool test = false}) async {
    Map<String, dynamic> sortedDataMap = await createSortedData(items);
    if (sortedDataMap['sortedData'].isEmpty) {
      return null;
    }
    List<List<CellValue>> sheetData = sortedDataMap['sortedData'];
    if(start == null){
      start = sortedDataMap['start'];
    }
    DateTime? end = sortedDataMap['end'];
    List<List<List<CellValue>>> sheets = [sheetData];
    List<String> types = [type];

    if(type == "experiments"){
      String year = start!.year.toString();
      List<String> allExpNests = [];
      allExpNests.addAll(items.expand((e) => (e as Experiment).nests ?? []).cast<String>().toList());
        if(allExpNests.isNotEmpty){
        QuerySnapshot nests = await firestore
            .collection(year)
            .where(FieldPath.documentId, whereIn: allExpNests)
            .get();
        if(nests.docs.isNotEmpty){
          List<FirestoreItem> nestItems = nests.docs.map((e) => Nest.fromDocSnapshot(e)).toList();
          Map<String, dynamic> nestSortedDataMap = await createSortedData(nestItems);
          List<List<CellValue>> nestSheetData = nestSortedDataMap['sortedData'];
          start = nestSortedDataMap['start'];
          end = nestSortedDataMap['end'];
          sheets.add(nestSheetData);
          types.add("nests");
        }
      }
      List<String> allExpsBirds = [];
      allExpsBirds.addAll(items.expand((e) => (e as Experiment).birds ?? []).cast<String>().toList());
      if(allExpsBirds.isNotEmpty){
        QuerySnapshot birds = await firestore
            .collection("Bird")
            .where(FieldPath.documentId, whereIn: allExpsBirds)
            .get();
        if(birds.docs.isNotEmpty){
          List<FirestoreItem> birdItems = birds.docs.map((e) => Bird.fromDocSnapshot(e)).toList();
          Map<String, dynamic> birdSortedDataMap = await createSortedData(birdItems);
          List<List<CellValue>> birdSheetData = birdSortedDataMap['sortedData'];
          sheets.add(birdSheetData);
          types.add("birds");
        }
      }
    }

    if (type == "nests" || type == "experiments") {
      if (start != null && end != null) {
        Timestamp startTimestamp = Timestamp.fromDate(start);
        Timestamp endTimestamp = Timestamp.fromDate(end);
        //get all eggs between start and end
        QuerySnapshot eggs = await firestore
            .collectionGroup("egg")
            .where("discover_date", isGreaterThanOrEqualTo: startTimestamp)
            .where("discover_date", isLessThanOrEqualTo: endTimestamp)
            .get();
        if (eggs.docs.isNotEmpty) {
          List<FirestoreItem> eggItems =
              eggs.docs.map((e) => Egg.fromDocSnapshot(e)).toList();
          Map<String, dynamic> eggSortedDataMap = await createSortedData(eggItems);
          List<List<CellValue>> eggSheetData = eggSortedDataMap['sortedData'];
          sheets.add(eggSheetData);
          types.add("egg");
        }
      }
    }

    if (sheets.isNotEmpty && !test) {
      print(sheets);
      return await saveAsExcel(sheets, types);
    } else if (test) {
      return sheets;
    } else {
      return null;
    }
  }

  Future<dynamic> saveAsExcel(
      List<List<List<CellValue>>> sheets, List<String> types,
      {bool testOnly = false}) async {
    Excel excel = Excel.createExcel(); // Create a new Excel file

    for (int i = 0; i < sheets.length; i++) {
      String type = types[i];
      List<List<CellValue>> rows = sheets[i];
      Sheet sheet = excel[type]; // Access a sheet
      //excel.delete("Sheet1"); // Delete the default sheet (Sheet1)

      CellStyle headStyle =
          CellStyle(backgroundColorHex: ExcelColor.black12, bold: true);
      CellStyle bodyStyle =
          CellStyle(backgroundColorHex: ExcelColor.none, bold: false);
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

    //remove the default sheet
    try {
      excel.delete("Sheet1");
    } catch (e) {
      print(e);
    }

    if (testOnly) {
      return excel;
    }
    return (saveAndShareExcelFile(types, excel));
  }

  Future<void> saveAndShareExcelFile(List<String> types, Excel excel) async {
    String fName =
        types.join("_") + "_" + DateTime.now().toIso8601String() + ".xlsx";

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
                'Sharing ${types.join(", ")} file from Bird Colony app. Downloaded on ${DateTime.now().toIso8601String()}');
        //delete the file from local storage
        saveFile.delete();
        return;
      }
    } else {
      // If the platform is web
      excel.save(fileName: fName);
      return;
    }
  }
}
