import 'package:kakrarahu/models/experiment.dart';

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
        measures.add(measureFromJson(v));
      });
    }
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
      measures.add(Measure(
          name: "note",
          type: "nest",
          value: "",
          isNumber: false,
          unit: "",
          modified: DateTime.now()));
    }

    measures.sort();
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



}