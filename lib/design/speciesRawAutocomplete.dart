import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';

class SpeciesRawAutocomplete extends StatefulWidget {
  final Function(Species) returnFun;
  final LocalSpeciesList speciesList;
  final String labelTxt;
  final Species species;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final Color labelColor;

  SpeciesRawAutocomplete({
    required this.species,
    required this.returnFun,
    required this.speciesList,
    this.bgColor = Colors.amberAccent,
    this.textColor = Colors.black,
    this.borderColor = Colors.deepOrange,
    this.labelColor = Colors.yellow,
    this.labelTxt = "species",
  });

  @override
  _SpeciesRawAutocompleteState createState() => _SpeciesRawAutocompleteState();
}

class _SpeciesRawAutocompleteState extends State<SpeciesRawAutocomplete> {
  final TextEditingController species = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    species.text = widget.species.english;
  }

  @override
  void didUpdateWidget(SpeciesRawAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.species != oldWidget.species) {
      species.text = widget.species.english;
    }
  }

  String _displayStringForOption(Species option) => option.english;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Species>(
      displayStringForOption: _displayStringForOption,
      focusNode: _focusNode,
      textEditingController: species,
      onSelected: (selected) {
        widget.returnFun(selected);
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
                  textColor: widget.textColor,
                  contentPadding: EdgeInsets.all(0),
                  visualDensity: VisualDensity.comfortable,
                  tileColor: widget.bgColor,
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
        return Padding(padding:
            EdgeInsets.fromLTRB(5, 10, 5, 0),
        child:TextFormField(
          textAlign: TextAlign.center,
          controller: textEditingController,
          decoration: InputDecoration(
            labelText: widget.labelTxt,
            labelStyle: TextStyle(color: widget.labelColor),
            hintText: "enter species",
            fillColor: widget.bgColor,
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: (BorderSide(color: Colors.indigo))),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(
                color: widget.borderColor,
                width: 1.5,
              ),
            ),
          ),
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
            //search the value in the species list
            Species species = widget.speciesList.getSpecies(value);

            if (species.english.isEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.black87,
                    title: Text('Invalid Species'),
                    content: Text('The entered species is not valid. Keep it?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Keep', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          widget.returnFun(Species(
                              english: value,
                              local: '',
                              latinCode: ''));
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              widget.returnFun(species);
              FocusScope.of(context).unfocus();
            }
          },
        ));
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Species>.empty();
        }
        return widget.speciesList.species.map((Species option) {
          return option;
        }).where((Species option) {
          return option.english
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
    );
  }
}
