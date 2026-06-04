import 'package:flutter/material.dart';

import '../models/firestore/experiment.dart';

class ExperimentDropdown extends StatefulWidget {
  final List<Experiment> allExperiments;
  final String? selectedExperiment;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  ExperimentDropdown({
    required this.allExperiments,
    required this.selectedExperiment,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  _ExperimentDropdownState createState() => _ExperimentDropdownState();
}

class _ExperimentDropdownState extends State<ExperimentDropdown> {
  String? _selectedExperiment;

  @override
  void initState() {
    super.initState();
    _selectedExperiment = widget.selectedExperiment;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.amberAccent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.deepOrange, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedExperiment,
          isExpanded: true,
          dropdownColor: Colors.amberAccent,
          iconEnabledColor: Colors.black87,
          iconDisabledColor: Colors.black45,
          hint: Text("Select experiment",
              style: TextStyle(color: Colors.black87)),
          style: TextStyle(color: Colors.black87),
          items: widget.allExperiments.map((Experiment e) {
            return DropdownMenuItem<String>(
              value: e.name,
              child: Text(e.name, style: TextStyle(color: Colors.black87)),
            );
          }).toList(),
          onChanged: widget.enabled
              ? (String? newValue) {
                  setState(() {
                    _selectedExperiment = newValue;
                  });
                  widget.onChanged(newValue);
                }
              : null,
        ),
      ),
    );
  }
}
