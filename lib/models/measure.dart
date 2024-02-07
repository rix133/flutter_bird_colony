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


  Widget getMeasureForm(String nameLabel, String unit, bool isNumber){
    valueCntr.text = value;
    return new Column(
      children: <Widget>[
        TextFormField(
          keyboardType: isNumber?TextInputType.number:TextInputType.text,
          controller: valueCntr,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: nameLabel + " (" + unit + ")",
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
        ),
        SizedBox(height: 10)
      ],
    );
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
