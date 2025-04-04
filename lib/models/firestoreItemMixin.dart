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
  // Workaround Way to run functions on firestoreItems
  Future<UpdateResult> deleteFirestoreItem(
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

  String? getCellKey(CellValue cell) {
    if (cell is TextCellValue) {
      return cell.value.text;
    } else if (cell is DoubleCellValue) {
      return cell.value.toString();
    } else if (cell is IntCellValue) {
      return cell.value.toString();
    }
    return "";
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

  Future<Map<String, dynamic>> createSortedData(
      List<FirestoreItem> items, FirebaseFirestore firestore) async {
    DateTime? start;
    DateTime? end;
    List<Egg> otherItems = [];
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
        // check if the item is a class Nest and add its eggs
        if (item is Nest) {
          List<Egg> eggs = await item.eggs(firestore);
          otherItems.addAll(eggs);
          itemRows = await item.toExcelRows(otherItems: eggs);
        } else if (item is Bird) {
          Egg? egg = await item.getEgg(firestore);
          if (egg != null) {
            otherItems.add(egg);
            itemRows = await item.toExcelRows(otherItems: [egg]);
          } else {
            itemRows = await item.toExcelRows();
          }
        } else {
          itemRows = await item.toExcelRows();
        }
        //ensure data and headers have the same length
        for (var i = 0; i < itemRows.length; i++) {
          headers.add(item.toExcelRowHeader());
        }
        data.addAll(itemRows);
      }
      Set<TextCellValue> uniqueHeaders = headers.expand((e) => e).toSet();

      List<List<CellValue>> sortedData = [uniqueHeaders.toList()];
      for (var i = 0; i < data.length; i++) {
        Map<String, CellValue> rowMap = Map.fromIterables(
            headers[i].map((h) => getCellKey(h) ?? "empty"), data[i]);
        List<CellValue> sortedRow = uniqueHeaders
            .map((h) => rowMap.containsKey(getCellKey(h))
                ? rowMap[getCellKey(h)]!
                : TextCellValue(""))
            .toList();
        sortedData.add(sortedRow);
      }
      return {
        'start': start,
        'end': end,
        'sortedData': sortedData,
        'otherItems': otherItems
      };
    } else {
      return {'start': null, 'end': null, 'sortedData': [], 'otherItems': []};
    }
  }

  Future<List<List<List<CellValue>>>?> downloadChangeLog(
      Future<List<FirestoreItem>> items,
      String type,
      FirebaseFirestore firestore,
      {DateTime? start,
      bool test = false}) async {
    if (type == "nests") {
      List<String> types = ["nests"];
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
    //list to hold all eggs
    List<Egg> eggs = [];
    Map<String, dynamic> sortedDataMap =
        await createSortedData(items, firestore);
    if (sortedDataMap['sortedData'].isEmpty) {
      return null;
    }
    List<List<CellValue>> sheetData = sortedDataMap['sortedData'];
    if (start == null) {
      start = sortedDataMap['start'];
    }

    if (type == "nests" || type == "birds") {
      eggs.addAll(sortedDataMap['otherItems']);
    }

    List<List<List<CellValue>>> sheets = [sheetData];
    List<String> types = [type];

    if (type == "experiments") {
      String year = start?.year.toString() ?? DateTime.now().year.toString();
      List<String> allExpNests = [];
      allExpNests.addAll(items
          .expand((e) => (e as Experiment).nests ?? [])
          .cast<String>()
          .toList());
      if (allExpNests.isNotEmpty) {
        // Split allExpNests into chunks of 10
        List<List<String>> chunks =
            allExpNests.fold<List<List<String>>>([], (all, one) {
          if (all.isEmpty || all.last.length == 10)
            all.add([one]);
          else
            all.last.add(one);
          return all;
        });

        // Initialize an empty list to hold all nestItems
        List<FirestoreItem> allNestItems = [];

        // Perform a query for each chunk and gather all nestItems
        for (List<String> chunk in chunks) {
          QuerySnapshot nests = await firestore
              .collection(year)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          if (nests.docs.isNotEmpty) {
            List<FirestoreItem> nestItems =
                nests.docs.map((e) => Nest.fromDocSnapshot(e)).toList();
            allNestItems.addAll(nestItems);
          }
        }

        // Now process allNestItems
        if (allNestItems.isNotEmpty) {
          Map<String, dynamic> nestSortedDataMap =
              await createSortedData(allNestItems, firestore);
          List<List<CellValue>> nestSheetData = nestSortedDataMap['sortedData'];
          start = nestSortedDataMap['start'];
          eggs.addAll(nestSortedDataMap['otherItems']);
          sheets.add(nestSheetData);
          types.add("nests");
        }
      }
      List<String> allExpsBirds = [];
      allExpsBirds.addAll(items
          .expand((e) => (e as Experiment).birds ?? [])
          .cast<String>()
          .toList());
      if (allExpsBirds.isNotEmpty) {
        // Split allExpsBirds into chunks of 10
        var chunks = allExpsBirds.fold<List<List<String>>>([], (all, one) {
          if (all.isEmpty || all.last.length == 10)
            all.add([one]);
          else
            all.last.add(one);
          return all;
        });

        // Initialize an empty list to hold all birdItems
        List<FirestoreItem> allBirdItems = [];

        // Perform a query for each chunk and gather all birdItems
        for (var chunk in chunks) {
          QuerySnapshot birds = await firestore
              .collection("Bird")
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          if (birds.docs.isNotEmpty) {
            List<FirestoreItem> birdItems =
                birds.docs.map((e) => Bird.fromDocSnapshot(e)).toList();
            allBirdItems.addAll(birdItems);
          }
        }

        // Now process allBirdItems
        if (allBirdItems.isNotEmpty) {
          Map<String, dynamic> birdSortedDataMap =
              await createSortedData(allBirdItems, firestore);
          List<List<CellValue>> birdSheetData = birdSortedDataMap['sortedData'];
          eggs.addAll(birdSortedDataMap['otherItems']);
          sheets.add(birdSheetData);
          types.add("birds");
        }
      }
    }
    if (eggs.isNotEmpty) {
      Map<String, dynamic> eggSortedDataMap =
          await createSortedData(eggs, firestore);
      List<List<CellValue>> eggSheetData = eggSortedDataMap['sortedData'];
      sheets.add(eggSheetData);
      types.add("eggs");
    }

    if (sheets.isNotEmpty && !test) {
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
