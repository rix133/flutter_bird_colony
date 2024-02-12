
import 'package:flutter/material.dart';
import 'package:kakrarahu/species.dart';

Widget buildRawAutocomplete(TextEditingController species, FocusNode _focusNode) {
  String _displayStringForOption(SpeciesList option) => option.english;
  return RawAutocomplete<SpeciesList>(
    displayStringForOption: _displayStringForOption,
    focusNode: _focusNode,
    textEditingController: species,
    onSelected: (selectedString) {
      print(selectedString);
    },
    optionsViewBuilder: (context, onSelected, options) {
      return Scaffold(
        body: ListView.separated(
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                title: Text(
                  option.english.toString(),
                  textAlign: TextAlign.center,
                ),
                textColor: Colors.black,
                contentPadding: EdgeInsets.all(0),
                visualDensity: VisualDensity.comfortable,
                tileColor: Colors.orange[300],
                onTap: () {
                  onSelected(option);
                },
              );
            },
            separatorBuilder: (context, index) => Divider(
              height: 0,
            ),
            itemCount: options.length),
      );
    },
    fieldViewBuilder: (BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted) {
      return TextFormField(
        textAlign: TextAlign.center,
        controller: textEditingController,
        decoration: InputDecoration(
          labelText: "species",
          labelStyle: TextStyle(color: Colors.yellow),
          hintText: "enter species",
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
        focusNode: focusNode,
        onFieldSubmitted: (String value) {
          onFieldSubmitted();
          print('You just typed a new entry  $value');
          FocusScope.of(context).unfocus();
        },
      );
    },
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text == '') {
        return const Iterable<SpeciesList>.empty();
      }
      return Species.english.where((SpeciesList option) {
        return option
            .toString()
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase());
      });
    },
  );
}