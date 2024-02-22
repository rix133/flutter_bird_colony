import 'package:flutter/material.dart';
import 'package:kakrarahu/models/firestoreItem.dart';

class FilterDialog extends StatefulWidget {
  final Map<String, FilteredItem> initialFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  FilterDialog({
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  Map<String, FilteredItem> filters = {};

  @override
  void initState() {
    super.initState();
    filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text("Filter"),
      content: SingleChildScrollView(
        child: Column(
          children: filters.entries.map((entry) {
            return DropdownButton<String>(
              value: entry.value.value,
              style: TextStyle(color: Colors.deepPurpleAccent),
              items: entry.value.items.map((FirestoreItem e) {
                return DropdownMenuItem<String>(
                  value: e.name,
                  child: Text(e.name,
                      style: TextStyle(color: Colors.deepPurpleAccent)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  filters[entry.key] = FilteredItem(
                    value: newValue,
                    items: entry.value.items,
                  );
                });
                widget.onFiltersChanged(filters);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Close"),
        ),
      ],
    );
  }
}

class FilteredItem {
  final String? value;
  final List<FirestoreItem> items;

  FilteredItem({
    required this.value,
    required this.items,
  });
}