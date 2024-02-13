import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Measure implements Comparable<Measure>{
  String name = "";
  String value = "";
  bool isNumber = false;
  DateTime modified = DateTime.now();
  String unit = "";

  Measure({required this.name, required this.value, required this.isNumber, required this.unit, required  this.modified}){
    if(modified != null){
      this.modified = modified;
    }
  }

  toJson() {
    return {
      'name': name,
      'value': value,
      'isNumber': isNumber,
      'unit': unit,
      'modified': modified.toIso8601String()
    };
  }


  TextEditingController valueCntr = TextEditingController();

  setValue(String? value) {
    this.value = value ?? "";
    valueCntr.text = value ?? "";
  }

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



  ListTile getMeasureTile(){
    return ListTile(
      title: Text(name + ": " + value + (unit == "" ? "" : " " + unit)),
    );
  }


  @override
  int compareTo(Measure other) {
    int comp = this.name.compareTo(other.name);
    if (comp != 0) return comp;
    return this.modified.compareTo(other.modified);
  }

  ListTile getMeasureTileEdit(){
    valueCntr.text = value;
    return ListTile(
      title: Text(name + (unit == "" ? "" : " (" + unit + ")")),
      trailing: TextFormField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        controller: valueCntr,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: value,
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
    );
  }
  Row getMeasureFormWithAddButton(Function(Measure) onPressed){
    valueCntr.text = value;
    String label = name + (unit == "" ? "" : " (" + unit + ")");
    if(modified == null){
      modified = DateTime.now();
    }
    if(modified.year == DateTime.now().year && value.isNotEmpty){
      label = label + DateFormat('d MMM yyyy').format(modified);
    } else if(value.isNotEmpty){
      label = label + DateFormat('d MMM HH:mm').format(modified);
    }
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: valueCntr,
            keyboardType: isNumber?TextInputType.number:TextInputType.text,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.yellow),
              hintText: value,
              fillColor: Colors.orange,
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: (BorderSide(color: Colors.indigo))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(
                  color: Colors.deepOrange,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: Colors.black,),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.white60),
          ),
          onPressed: () {
            Measure newMeasure = Measure(name: name, value: "", isNumber: isNumber, unit: unit, modified: DateTime.now());
            onPressed(newMeasure);
          },
        )
      ],
    );
  }

  Row getNewMeasureForm(){
    //form to create a new measure with editable name and value
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: valueCntr,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: "Name",
              labelStyle: TextStyle(color: Colors.yellow),
              hintText: "Weight",
              fillColor: Colors.orange,
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: (BorderSide(color: Colors.indigo))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(
                  color: Colors.deepOrange,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            keyboardType: isNumber?TextInputType.number:TextInputType.text,
            controller: valueCntr,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: "Value",
              labelStyle: TextStyle(color: Colors.yellow),
              hintText: "12325",
              fillColor: Colors.orange,
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: (BorderSide(color: Colors.indigo))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(
                  color: Colors.deepOrange,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );

  }

}

Measure measureFromJson(Map<String, dynamic> json) {
  Measure m = Measure(
      name: json['name'],
      value: json['value'],
      isNumber: json['isNumber'],
      unit: json['unit'],
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : DateTime.now()
  );
  m.valueCntr.text = m.value;
  return m;
}
