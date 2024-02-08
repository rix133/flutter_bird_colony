import 'package:flutter/material.dart';

class Measure {
  String name = "";
  String value = "";
  bool isNumber = false;
  String unit = "";

  Measure({required this.name, required this.value, required this.isNumber, required this.unit});

  toJson() {
    return {
      'name': name,
      'value': valueCntr.text,
      'isNumber': isNumber,
      'unit': unit
    };
  }


  TextEditingController valueCntr = TextEditingController();


  Padding getMeasureForm(){
    valueCntr.text = value;
    return Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          keyboardType: isNumber?TextInputType.number:TextInputType.text,
          controller: valueCntr,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: name +  (unit == "" ? "" : " (" + unit + ")"),
            labelStyle: TextStyle(color: Colors.yellow),
            hintText: unit,
            fillColor: Colors.orange,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: (BorderSide(
                  color: Colors.indigo
              ))
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(
                color: Colors.deepOrange,
                width: 1.5,
              ),
            ),
          ),
        ));
  }

}

Measure measureFromJson(Map<String, dynamic> json) {
  return Measure(
      name: json['name'],
      value: json['value'],
      isNumber: json['isNumber'],
      unit: json['unit']
  );
}
