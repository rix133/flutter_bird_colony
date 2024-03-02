

import 'package:flutter/material.dart';

import '../models/firestore/experiment.dart';

class ExperimentDropdown extends StatefulWidget {
  final List<Experiment> allExperiments;
  final String? selectedExperiment;
  final ValueChanged<String?> onChanged;

  ExperimentDropdown({
    required this.allExperiments,
    required this.selectedExperiment,
    required this.onChanged,
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
    return DropdownButton<String>(
      value: _selectedExperiment,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: widget.allExperiments.map((Experiment e) {
        return DropdownMenuItem<String>(
          value: e.name,
          child: Text(e.name,
              style: TextStyle(color: Colors.deepPurpleAccent)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedExperiment = newValue;
        });
        widget.onChanged(newValue);
      },
    );
  }
}
