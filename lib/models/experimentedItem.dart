import 'dart:math' as math;

import 'package:excel/excel.dart';
import 'package:flutter_bird_colony/models/firestore/experiment.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';

import 'firestore/firestoreItem.dart';
import 'measure.dart';

class ExperimentedItem{
  List<Experiment>? experiments = [];
  List<Measure> measures = [];

  String get itemName => "item";

  ExperimentedItem({this.experiments, required this.measures});
  
  ExperimentedItem.fromJson(Map<String, dynamic> json){
    if (json['experiments'] != null) {
      experiments = [];
      json['experiments'].forEach((v) {
        experiments?.add(experimentFromSimpleJson(v));
      });
    }
    if (json['measures'] != null) {
      measures = [];
      json['measures'].forEach((v) {
        measures.add(Measure.fromJson(v));
      });
    }
  }

  List<UpdateResult> validate(SharedPreferencesService? sps,
      {List<FirestoreItem> otherItems = const []}) {
    List<UpdateResult> results = [];
    if (otherItems.isNotEmpty) {
      //check if there are any other items that cant pass validation
      for (FirestoreItem item in otherItems) {
        List<UpdateResult> subResult = item.validate(sps);
        results.addAll(subResult);
      }
    }
    if (measures.isNotEmpty) {
      for (Measure m in measures) {
        //get the name of the item
        if (m.isInvalid()) {
          UpdateResult err = UpdateResult.error(
              message:
                  "Measure ${m.name} on $itemName is required but not filled in!");
          results.add(err);
        }
      }
    }
    return results;
  }

  void dispose(){
    //I think I can't dispose these alway because they are sometimes
    //passed around
    /*
    experiments?.forEach((element) {
      element.dispose();
    });
    measures.forEach((element) {
      element.dispose();
    });
     */
  }

  addNonExistingExperiments(List<Experiment>? exps, String selType){
    if(exps == null) return;
    bool added = false;
    exps.forEach((Experiment e) {
      if(experiments?.where((element) => element.id == e.id).isEmpty ?? true){
        experiments?.add(e);
        added = true;
      }
    });
    //update measures if needed
    if(added){
      updateMeasuresFromExperiments(selType);
    }

  }

  void updateMeasuresFromExperiments(String selType) {
    experiments?.forEach((Experiment e) {
      e.measures.forEach((Measure m) {
        //add the measure if it does not exist and its type is parent chick or any
        if (measures.where((element) => element.name == m.name).isEmpty &&
            (m.type ==  selType || m.type == "any" )) {
          measures.add(m);
        }
      });
    });
    //add empty note if it does not exist
    if(measures.where((element) => element.name == "note").isEmpty){
      measures.add(Measure.note());
    }

    measures.sort();
  }

  void addMissingMeasures(List<Measure>? allMeasures, String? type) {
    if(allMeasures == null) return;
    //filter for type measures
    allMeasures = allMeasures.where((element) => element.type == type || element.type == "any").toList();
    for (Measure m in allMeasures) {
      //add if one with this name does not exist
      if (measures.where((element) => element.name == m.name).isEmpty) {
        measures.add(m);
      }
    }
  }

  Map<String, List<Measure>> getMeasuresMap(){
    Map<String, List<Measure>> measuresMap = {};
    int maxLen = 0;

    // Populate the measuresMap and find the maximum length
    for (Measure measure in measures) {
      if (measure.value.isNotEmpty) {
        // Only add measures with non-empty values
        if (!measuresMap.containsKey(measure.name)) {
          measuresMap[measure.name] = [measure];
          if (maxLen < 1) {
            maxLen = 1;
          }
        } else {
          measuresMap[measure.name]!.add(measure);
          int len = measuresMap[measure.name]!.length;
          if (len > maxLen) {
            maxLen = len;
          }
        }
      }
    }

    // Add empty Measure instances to make all lists the same length
    for (String key in measuresMap.keys) {
      List<Measure> list = measuresMap[key]!;
      while (list.length < maxLen) {
        list.add(Measure.empty(list[0]));
      }
    }
    return measuresMap;
  }

  List<List<CellValue>> addMeasuresToRow(List<CellValue> baseItems) {
    List<List<CellValue>> rows = [];
    Map<String, List<Measure>> measuresMap = getMeasuresMap();

      if (measuresMap.isNotEmpty) {
      int max = measuresMap.values.map((m) => m.length).reduce(math.max);
      List<List<List<CellValue>>> measures = measuresMap.values.map((m) => m.map((measure) => measure.toExcelRow()).toList()).toList();

      for (int i = 0; i < max; i++) {
        List<CellValue> row = List.from(baseItems);
        measures.forEach((measure) => row.addAll(i < measure.length ? measure[i] : [TextCellValue("")]));
        rows.add(row);
      }
    } else {
      rows.add(baseItems);
    }

    return rows;
  }




  bool get hasExperiments =>  experiments?.isNotEmpty ?? false;
  bool get hasMeasures =>  measures.isNotEmpty;
}