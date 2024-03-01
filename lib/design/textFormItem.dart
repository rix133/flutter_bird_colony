import 'package:flutter/material.dart';

class TextFormItem extends StatefulWidget {
final String label;
final String initialValue;
final bool isNumber;
final Function(String)? changeFun;

TextFormItem({
  required this.label,
  required this.initialValue,
  this.isNumber = false,
  required this.changeFun,
}) : super(key: Key(label));

@override
_TextFormItemState createState() => _TextFormItemState();
}

class _TextFormItemState extends State<TextFormItem> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }


  @override
  void didUpdateWidget(TextFormItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      controller.text = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                child: TextFormField(
                  keyboardType: widget.isNumber
                      ? TextInputType.number
                      : TextInputType.text,
                  controller: controller,
                  textAlign: TextAlign.center,
                  onChanged: widget.changeFun,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    labelStyle: TextStyle(color: Colors.yellow),
                    hintText: widget.label,
                    fillColor: Colors.orange,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: Colors.indigo,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                        color: Colors.deepOrange,
                        width: 1.5,
                      ),
                    ),
                  ),
                ))),
      ],
    );
  }
}
