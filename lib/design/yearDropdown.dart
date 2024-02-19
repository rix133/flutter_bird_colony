import 'package:flutter/material.dart';

class YearDropdown extends StatefulWidget {
  final int selectedYear;
  final ValueChanged<int> onChanged;

  YearDropdown({
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  _YearDropdownState createState() => _YearDropdownState();
}

class _YearDropdownState extends State<YearDropdown> {
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: _selectedYear,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: List<int>.generate(DateTime.now().year - 2022 + 1,
              (int index) => index + 2022).map((int year) {
        return DropdownMenuItem<int>(
          value: year,
          child: Text(year.toString(),
              style: TextStyle(color: Colors.deepPurpleAccent)),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedYear = newValue!;
        });
        widget.onChanged(newValue!);
      },
    );
  }
}


