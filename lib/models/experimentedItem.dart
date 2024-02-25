import 'package:excel/excel.dart';
import 'package:kakrarahu/models/experiment.dart';
import 'dart:math' as math;

import 'measure.dart';

class ExperimentedItem{
  List<Experiment>? experiments = [];
  List<Measure> measures = [];
  
  
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
    for (Measure measure in measures) {
      if (!measuresMap.containsKey(measure.name)) {
        measuresMap[measure.name] = [measure];
      } else {
        measuresMap[measure.name]!.add(measure);
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