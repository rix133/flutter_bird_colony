import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Measure implements Comparable<Measure> {
  String name = "";
  String value = "";
  bool isNumber = false;
  DateTime modified = DateTime.now();
  String unit = "";
  bool repeated = false;
  bool required = false;
  String type=  "any";

  Measure(
      {required this.name,
      required this.value,
      required this.isNumber,
      required this.unit,
      required this.modified,
      required this.type,
      this.repeated = false,
      this.required = false}) {
    this.valueCntr.text = value;
  }

  Measure copy() {
    return Measure(
        name: name,
        value: value,
        isNumber: isNumber,
        unit: unit,
        modified: modified,
        type: type,
        required: required,
        repeated: repeated);
  }

  Measure.note({this.value = ""}){
    this.unit = "";
    this.name = "note";
    this.isNumber = false;
    this.repeated = true;
    this.required = false;
    this.valueCntr.text = value;
  }

  factory Measure.numeric(
      {required name,
      value = "",
      unit = "",
      type = "any",
      bool repeated = false,
      bool required = false}) {
    return Measure(
        name: name,
        value: value,
        isNumber: true,
        unit: unit,
        modified: DateTime.now(),
        type: type,
        repeated: repeated,
        required: required);
  }

  factory Measure.text(
      {required name,
      value = "",
      unit = "",
      type = "any",
      bool repeated = false,
      bool required = false}) {
    return Measure(
        name: name,
        value: value,
        isNumber: false,
        unit: unit,
        modified: DateTime.now(),
        type: type,
        repeated: repeated,
        required: required);
  }

  factory Measure.empty(Measure m){
    return Measure(
        name: m.name,
        value: "",
        isNumber: m.isNumber,
        unit: m.unit,
        modified: DateTime.now(),
        type: m.type,
        repeated: m.repeated,
        required: m.required);
  }

  toJson() {
    return {
      'name': name,
      'type': type,
      'value': value,
      'isNumber': isNumber,
      'unit': unit,
      'modified': modified.toIso8601String(),
      'required': required,
      'repeated': repeated
    };
  }

  toFormJson() {
    return {
      'name': name,
      'type': type,
      'isNumber': isNumber,
      'required': required,
      'repeated': repeated,
      'unit': unit
    };
  }

  List<CellValue> toExcelRow(){
    double? vd = isNumber ? double.tryParse(value) : null;
    return [
      (isNumber && vd != null) ? DoubleCellValue(vd) : TextCellValue(value),
      DateTimeCellValue.fromDateTime(modified)];
  }

  List<TextCellValue> toExcelRowHeader() {
    return [
      TextCellValue(name + "_" + unit),
      TextCellValue(name + '_time')
    ];
  }

  void dispose() {
    valueCntr.dispose();
  }

  bool isInvalid() {
    return required && value.isEmpty;
  }

  TextEditingController valueCntr = TextEditingController();

  setValue(String? value){
    this.value = value ?? "";
    this.valueCntr.text = value ?? "";
  }

  Widget createMeasureForm(Function setState){
    TextEditingController nameCntr = TextEditingController(text: name);
    TextEditingController unitCntr = TextEditingController(text: unit);
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            key: Key("nameMeasureEdit"),
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
            key: Key("typeMeasureEdit"),
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
          SwitchListTile(
            title: const Text('Repeated'),
            value: this.repeated,
            onChanged: (bool value) {
              setState(() {
                this.repeated = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Required'),
            value: this.required,
            onChanged: (bool value) {
              setState(() {
                this.required = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget getMeasureForm(Function(Measure) onPressed, bool showValue){
    bool hideValue = !showValue;
    if(name.contains("note")){
      hideValue = false;
    }
    return repeated ? getMeasureFormWithAddButton(onPressed, hideValue) : getSimpleMeasureForm();
  }


  Padding getSimpleMeasureForm(){
    return Padding(
        padding: EdgeInsets.all(5),
        child: TextFormField(
          keyboardType: isNumber?TextInputType.number:TextInputType.text,
          controller: valueCntr,
          onChanged: (value) {
            this.value = value;
          },
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: name +
                (unit == "" ? "" : " (" + unit + ")" + (required ? "*" : "")),
            labelStyle: TextStyle(color: Colors.yellow),
            hintText: unit,
            fillColor: (required && value.isEmpty) ? Colors.red : Colors.orange,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: (BorderSide(
                  color: Colors.indigo
              ))
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(
                color: (required && value.isEmpty)
                    ? Colors.red
                    : Colors.deepOrange,
                width: 1.5,
              ),
            ),
          ),
        ));
  }



  ListTile getListTile(BuildContext context, onSaved, onRemoved){
    return ListTile(
      title: Text(name.isEmpty
          ? "undefined"
          : name + (unit == "" ? "" : " (" + unit + ")")),
      subtitle: Text("on: " + type + (repeated ? " (repeated)" : " (single)")),
      trailing: ElevatedButton.icon(
          onPressed:  () => showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: Text('Edit Measure'),
              content: StatefulBuilder(  // Add this
                builder: (BuildContext context, StateSetter alertDialogSetState) {
                  return createMeasureForm(alertDialogSetState);  // Pass alertDialogSetState here
                },
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    onRemoved(this);
                    Navigator.pop(context);
                  },
                  child: Text('Remove'),
                ),
                ElevatedButton(
                    key: Key("doneMeasureEditButton"),
                    onPressed: () {
                    onSaved(this);
                    Navigator.pop(context);
                  },
                    child: Text('Done'),
                  ),
              ],
            );
          }
          ),
        icon: Icon(Icons.edit, color: Colors.black),
        label: Text("Edit"),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.white60),
        ),
      ),
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
      title: Text(
          name + (unit == "" ? "" : " (" + unit + ")" + (required ? "*" : ""))),
      trailing: TextFormField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        controller: valueCntr,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: value,
          labelStyle: TextStyle(color: Colors.yellow),
          hintText: unit,
          fillColor: (required && value.isEmpty) ? Colors.red : Colors.orange,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: (BorderSide(
                  color: Colors.indigo
              ))
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(
              color:
                  (required && value.isEmpty) ? Colors.red : Colors.deepOrange,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget getMeasureFormWithAddButton(
      Function(Measure) onPressed, bool hideValue) {
    String label = name + (unit == "" ? "" : " (" + unit + ")");
    if(modified.year == DateTime.now().year && value.isNotEmpty){
      label = label + " " + DateFormat('d MMM yyyy').format(modified);
    } else if(value.isNotEmpty){
      label = label + " " + DateFormat('d MMM HH:mm').format(modified);
    }
    if(value.isEmpty){
      hideValue = false;
    } else{
      if(hideValue){
        valueCntr.text = "???";
      }
    }

    return Padding(
        padding: EdgeInsets.all(5),
        child: Row(
          children: [
        Expanded(
          child: TextFormField(
            controller: valueCntr,
            keyboardType: isNumber?TextInputType.number:TextInputType.text,
            textAlign: TextAlign.center,
            readOnly: hideValue,
            onChanged: (value) {
              hideValue ? null : this.value = value;
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.yellow),
              hintText: value,
                  fillColor:
                      (required && value.isEmpty) ? Colors.red : Colors.orange,
                  focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: (BorderSide(color: Colors.indigo))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(
                      color: (required && value.isEmpty)
                          ? Colors.red
                          : Colors.deepOrange,
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
            Measure newMeasure = Measure.empty(this);
            onPressed(newMeasure);
          },
        )
      ],
        ));
  }
  factory Measure.fromJson(Map<String, dynamic> json) {
    Measure m = Measure(
        name: json['name'],
        value: json['value'],
        isNumber: json['isNumber'],
        unit: json['unit'],
        type: json['type'] ?? "any",
        modified: json['modified'] != null ? DateTime.parse(json['modified']) : DateTime.now(),
        repeated: json['repeated'] ?? false,
        required: json['required'] ?? false);
    return m;
  }

  factory Measure.fromFormJson(Map<String, dynamic> json) {
    Measure m = Measure(
        name: json['name'],
        value: "",
        isNumber: json['isNumber'],
        unit: json['unit'],
        type: json['type'] ?? "any",
        modified: DateTime.now(),
        repeated: json['repeated'] ?? false,
        required: json['required'] ?? false);
    return m;
  }

}


