import 'package:flutter/material.dart';

class MinMaxInput extends StatefulWidget {
  final String label;
  final Function(String) minFun;
  final Function(String) maxFun;
  final double? min;
  final double? max;

  MinMaxInput({
    required this.label,
    required this.minFun,
    required this.maxFun,
    this.min,
    this.max,
  });

  @override
  _MinMaxInputState createState() => _MinMaxInputState();
}

class _MinMaxInputState extends State<MinMaxInput> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        Text(widget.label),
        SizedBox(width: 10),
        Expanded(
            child: TextFormField(
                key: Key(widget.label + "Min"),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Min",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
                initialValue: widget.min?.toString() ?? "",
                onChanged: widget.minFun)),
        SizedBox(width: 10),
        Expanded(
            child: TextFormField(
                key: Key(widget.label + "Max"),
                keyboardType: TextInputType.number,
                initialValue: widget.max?.toString() ?? "",
                decoration: InputDecoration(
                  labelText: "Max",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
                onChanged: widget.maxFun)),
      ]),
    );
  }
}
