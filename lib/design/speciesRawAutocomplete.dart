import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/species.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:provider/provider.dart';

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
  SpeciesNameLanguage _lastLanguage = SpeciesNameLanguage.english;

  @override
  void initState() {
    super.initState();
    species.text = _primaryName(
        _resolveDisplaySpecies(widget.species),
        _lastLanguage);
  }

  @override
  void didUpdateWidget(SpeciesRawAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.species != oldWidget.species ||
        widget.speciesList != oldWidget.speciesList) {
      species.text = _primaryName(
          _resolveDisplaySpecies(widget.species),
          _lastLanguage);
    }
  }

  SharedPreferencesService? _maybeSps(BuildContext context) {
    try {
      return Provider.of<SharedPreferencesService>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  SpeciesNameLanguage _resolveLanguage(BuildContext context) {
    final sps = _maybeSps(context);
    return sps?.speciesNameLanguage ?? SpeciesNameLanguage.english;
  }

  Species _resolveDisplaySpecies(Species source) {
    if (source.local.trim().isNotEmpty ||
        source.english.trim().isEmpty) {
      return source;
    }
    final listMatch = widget.speciesList.getSpecies(source.english);
    if (listMatch.local.trim().isEmpty) {
      return source;
    }
    return listMatch;
  }

  String _primaryName(Species option, SpeciesNameLanguage language) {
    final local = option.local.trim();
    if (language == SpeciesNameLanguage.local && local.isNotEmpty) {
      return local;
    }
    return option.english.trim();
  }

  String _secondaryName(Species option, SpeciesNameLanguage language) {
    final local = option.local.trim();
    final english = option.english.trim();
    if (language == SpeciesNameLanguage.local) {
      if (local.isEmpty || english.isEmpty || english == local) {
        return '';
      }
      return english;
    }
    if (local.isEmpty || local == english) {
      return '';
    }
    return local;
  }

  @override
  Widget build(BuildContext context) {
    final displayLanguage = _resolveLanguage(context);
    if (displayLanguage != _lastLanguage) {
      _lastLanguage = displayLanguage;
      if (!_focusNode.hasFocus) {
        species.text = _primaryName(
            _resolveDisplaySpecies(widget.species),
            displayLanguage);
      }
    }
    return RawAutocomplete<Species>(
      displayStringForOption: (option) =>
          _primaryName(option, displayLanguage),
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
                final primary = _primaryName(option, displayLanguage);
                final secondary = _secondaryName(option, displayLanguage);
                return ListTile(
                  title: Text(
                    primary,
                    textAlign: TextAlign.center,
                  ),
                  subtitle: secondary.isEmpty
                      ? null
                      : Text(
                          secondary,
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
            hintText: "enter species",
          ),
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
            //search the value in the species list
            Species species =
                widget.speciesList.getSpeciesByName(value);

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
        final query = textEditingValue.text.toLowerCase();
        return widget.speciesList.species.map((Species option) {
          return option;
        }).where((Species option) {
          return option.english.toLowerCase().contains(query) ||
              option.local.toLowerCase().contains(query);
        });
      },
    );
  }
}
