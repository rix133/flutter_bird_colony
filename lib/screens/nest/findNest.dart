import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/buildForm.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:provider/provider.dart';

import '../../services/sharedPreferencesService.dart';

enum FindTarget { nest, birdMetalBand, birdColorBand }

class FindNest extends StatefulWidget {
  final FirebaseFirestore firestore;
  const FindNest({Key? key, required this.firestore}) : super(key: key);

  @override
  State<FindNest> createState() => _FindNestState();
}

class _FindNestState extends State<FindNest> {
  SharedPreferencesService? sps;
  CollectionReference? nests;
  CollectionReference? birds;

  final FocusNode _focusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  FindTarget _target = FindTarget.nest;
  bool _searching = false;
  Timer? _snackTimer;

  @override
  void initState() {
    super.initState();
    nests = widget.firestore
        .collection(yearToNestCollectionName(DateTime.now().year));
    birds = widget.firestore.collection("Birds");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sps = Provider.of<SharedPreferencesService>(context, listen: false);
      nests = widget.firestore.collection(
          yearToNestCollectionName(sps?.selectedYear ?? DateTime.now().year));
      setState(() {});
    });
  }

  @override
  void dispose() {
    _snackTimer?.cancel();
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetSearchState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _searching = false;
    });
  }

  void _submitSearch() {
    if (_searching) {
      return;
    }
    setState(() {
      _searching = true;
    });
    _search(searchController.text);
  }

  Future<void> _search(String target) async {
    final query = target.trim().toUpperCase();
    if (query.isEmpty) {
      _resetSearchState();
      return;
    }

    try {
      switch (_target) {
        case FindTarget.nest:
          await _searchNest(query);
          break;
        case FindTarget.birdMetalBand:
          await _searchBirdByMetalBand(query);
          break;
        case FindTarget.birdColorBand:
          await _searchBirdByColorBand(query);
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error searching"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      _resetSearchState();
    }
  }

  Future<void> _searchNest(String query) async {
    if (nests == null) {
      return;
    }
    final data = await nests!.doc(query).get();
    if (data.exists) {
      searchController.clear();
      Navigator.pushNamed(context, '/editNest',
          arguments: {"nest": Nest.fromDocSnapshot(data)});
    } else {
      _showNotFound("Nest $query does not exist");
    }
  }

  Future<void> _searchNestOnMap() async {
    final query = searchController.text.trim().toUpperCase();
    if (query.isEmpty || nests == null) {
      return;
    }
    final data = await nests!.doc(query).get();
    if (!data.exists) {
      _showNotFound("Nest $query does not exist");
      return;
    }
    final selectedYear = sps?.selectedYear ?? DateTime.now().year;
    Navigator.pushNamed(context, '/mapNests', arguments: {
      "nest_ids": [query],
      "year": selectedYear,
    });
  }

  Future<void> _searchBirdByMetalBand(String query) async {
    if (birds == null) {
      return;
    }
    final data = await birds!.doc(query).get();
    if (data.exists) {
      _openBird(Bird.fromDocSnapshot(data));
      return;
    }
    _showNotFound("Bird with metal band $query does not exist");
  }

  Future<void> _searchBirdByColorBand(String query) async {
    if (birds == null) {
      return;
    }
    final results =
        await birds!.where('color_band', isEqualTo: query).limit(5).get();
    if (results.docs.isEmpty) {
      _showNotFound("Bird with color band $query does not exist");
      return;
    }
    final birdsFound =
        results.docs.map((doc) => Bird.fromDocSnapshot(doc)).toList();
    if (birdsFound.length == 1) {
      _openBird(birdsFound.first);
      return;
    }
    await _showBirdPicker(birdsFound);
  }

  void _openBird(Bird bird) {
    searchController.clear();
    Navigator.pushNamed(context, '/editBird', arguments: {"bird": bird});
  }

  Future<void> _showBirdPicker(List<Bird> birdsFound) async {
    if (!mounted) {
      return;
    }
    final Bird? selected = await showDialog<Bird>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select bird"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: birdsFound.length,
              itemBuilder: (context, index) {
                final bird = birdsFound[index];
                return ListTile(
                  title: Text(bird.name),
                  subtitle: Text(bird.band.isNotEmpty
                      ? "Metal band: ${bird.band}"
                      : "Color band: ${bird.color_band ?? "unknown"}"),
                  onTap: () => Navigator.pop(context, bird),
                );
              },
            ),
          ),
        );
      },
    );
    if (selected != null) {
      _openBird(selected);
    }
  }

  void _showNotFound(String message) {
    if (!mounted) {
      return;
    }
    _focusNode.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.redAccent,
      ),
    );
    _snackTimer?.cancel();
    _snackTimer = Timer(Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: (sps?.showAppBar ?? true)
          ? AppBar(
              title: Text('Search nests'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                buildForm(
                  context,
                  _target == FindTarget.nest
                      ? "enter nest ID"
                      : _target == FindTarget.birdMetalBand
                          ? "enter metal band"
                          : "enter color band",
                  null,
                  searchController,
                  _target == FindTarget.nest,
                  (_) => _submitSearch(),
                  _focusNode,
                ),
                ElevatedButton.icon(
                    key: Key('findNestButton'),
                    onPressed: _searching ? null : _submitSearch,
                    icon: Icon(
                    Icons.search,
                    color: Colors.black87,
                    size: 32,
                    ),
                    label: Text(
                      _target == FindTarget.nest ? "Find nest" : "Find bird"),
                    style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  if (_target == FindTarget.nest) ...[
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    key: Key('findNestOnMapButton'),
                    onPressed: _searching ? null : _searchNestOnMap,
                    icon: Icon(Icons.map_outlined),
                    label: Text("Find on map"),
                  ),
                ],
                SizedBox(height: 16),
                DropdownButton<FindTarget>(
                  key: Key('findTargetDropdown'),
                  value: _target,
                  items: const <DropdownMenuItem<FindTarget>>[
                    DropdownMenuItem<FindTarget>(
                      value: FindTarget.nest,
                      child: Text("Nest"),
                    ),
                    DropdownMenuItem<FindTarget>(
                      value: FindTarget.birdMetalBand,
                      child: Text("Bird metal band"),
                    ),
                    DropdownMenuItem<FindTarget>(
                      value: FindTarget.birdColorBand,
                      child: Text("Bird color band"),
                    ),
                  ],
                  onChanged: (FindTarget? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _target = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
