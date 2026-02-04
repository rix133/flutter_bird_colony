import 'package:flutter/material.dart';

class YearDropdown extends StatefulWidget {
  final int selectedYear;
  final ValueChanged<int> onChanged;
  final Key? dropdownKey;

  YearDropdown({
    this.dropdownKey,
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
    const startYear = 2022;
    final maxYear = DateTime.now().year > widget.selectedYear
        ? DateTime.now().year
        : widget.selectedYear;
    final years = maxYear >= startYear
        ? List<int>.generate(
            maxYear - startYear + 1, (int index) => index + startYear)
        : <int>[maxYear];
    return DropdownButton<int>(
      key: widget.dropdownKey,
      value: _selectedYear,
      style: TextStyle(color: Colors.deepPurpleAccent),
      items: years.map((int year) {
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


