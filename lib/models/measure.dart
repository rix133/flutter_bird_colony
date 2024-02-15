import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Measure implements Comparable<Measure>{
  String name = "";
  String value = "";
  bool isNumber = false;
  DateTime modified = DateTime.now();
  String unit = "";
  String type=  "any";

  Measure({required this.name, required this.value, required this.isNumber, required this.unit, required  this.modified, required this.type}){
      this.valueCntr.text = value;
  }

  Measure.numeric({required this.name, required this.value, required this.unit, required this.modified}){
    this.isNumber = true;
    this.valueCntr.text = value;
  }
  Measure.text({required this.name, required this.value, required this.unit, required this.modified}){
    this.isNumber = false;
    this.valueCntr.text = value;
  }

  toJson() {
    return {
      'name': name,
      'type': type,
      'value': value,
      'isNumber': isNumber,
      'unit': unit,
      'modified': modified.toIso8601String()
    };
  }

  toFormJson() {
    return {
      'name': name,
      'type': type,
      'isNumber': isNumber,
      'unit': unit
    };
  }


  TextEditingController valueCntr = TextEditingController();

  setValue(String? value){
    this.value = value ?? "";
    this.valueCntr.text = value ?? "";
  }

  Form createMeasureForm(Function setState){
    TextEditingController nameCntr = TextEditingController(text: name);
    TextEditingController unitCntr = TextEditingController(text: unit);
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: nameCntr,
            onChanged: (value) {
              this.name = value;
            },
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Age, weight, ...',
            ),
          ),
          TextFormField(
            controller: unitCntr,
            onChanged: (value) {
              this.unit = value;
            },
            decoration: InputDecoration(
              labelText: 'Unit',
              hintText: 'g, m, ...',
            ),
          ),
          DropdownButtonFormField<String>(
            value: this.type,
            onChanged: (String? newValue) {
              setState(() {
                this.type = newValue ?? "any";
              });
            },
            items: <String>['any', 'nest', 'parent', 'chick', 'egg']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: Colors.purple),),
              );
            }).toList(),
          ),
          SwitchListTile(
            title: const Text('Is Numeric'),
            value: this.isNumber,
            onChanged: (bool value) {
              setState(() {
                this.isNumber = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Padding getMeasureForm(){
    return Padding(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          keyboardType: isNumber?TextInputType.number:TextInputType.text,
          controller: valueCntr,
          onChanged: (value) {
            this.value = value;
          },
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
    String label = name + (unit == "" ? "" : " (" + unit + ")");
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
            onChanged: (value) {
              this.value = value;
            },
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
            Measure newMeasure = Measure(name: name, value: "", isNumber: isNumber, type:  type, unit: unit, modified: DateTime.now());
            onPressed(newMeasure);
          },
        )
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
      type: json['type'] ?? "any",
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : DateTime.now()
  );
  return m;
}

Measure measureFromFormJson(Map<String, dynamic> json) {
  Measure m = Measure(
      name: json['name'],
      value: "",
      isNumber: json['isNumber'],
      unit: json['unit'],
      type: json['type'] ?? "any",
      modified: DateTime.now()
  );
  return m;
}
