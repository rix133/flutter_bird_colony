import 'package:flutter/material.dart';

class TextFormItem extends StatefulWidget {
final String label;
final String initialValue;
final bool isNumber;
final FocusNode? focus;
final Function(String)? changeFun;
final Function(String)? submitFun;

TextFormItem({
  required this.label,
  required this.initialValue,
  this.isNumber = false,
  this.focus,
  this.changeFun,
  this.submitFun,
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
  dispose() {
    controller.dispose();
    super.dispose();
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
                  focusNode: widget.focus,
                  controller: controller,
                  textAlign: TextAlign.center,
                  onChanged: widget.changeFun,
                  onFieldSubmitted: widget.submitFun,
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
