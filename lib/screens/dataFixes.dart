import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/models/firestore/bird.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:provider/provider.dart';

import '../design/yearDropdown.dart';

class DataFixes extends StatefulWidget {
  final FirebaseFirestore firestore;
  const DataFixes({Key? key, required this.firestore}) : super(key: key);

  @override
  State<DataFixes> createState() => _DataFixesState();
}

class _DataFixesState extends State<DataFixes> {
  final TextEditingController _moveBandCntr = TextEditingController();
  final TextEditingController _moveNestCntr = TextEditingController();
  final TextEditingController _moveEggCntr = TextEditingController();

  final TextEditingController _swapBandACntr = TextEditingController();
  final TextEditingController _swapBandBCntr = TextEditingController();

  SharedPreferencesService? _sps;

  int _moveYear = DateTime.now().year;

  bool _moveBusy = false;
  bool _swapBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sps = Provider.of<SharedPreferencesService>(context, listen: false);
      final selectedYear = _sps?.selectedYear ?? DateTime.now().year;
      setState(() {
        _moveYear = selectedYear;
      });
    });
  }

  @override
  void dispose() {
    _moveBandCntr.dispose();
    _moveNestCntr.dispose();
    _moveEggCntr.dispose();
    _swapBandACntr.dispose();
    _swapBandBCntr.dispose();
    super.dispose();
  }

  String _normalizeBand(String input) => input.trim().toUpperCase();

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: Duration(seconds: isError ? 6 : 4),
    ));
  }

  Future<bool> _confirmAction(String title, String message) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        });
    return result ?? false;
  }

  Future<Map<String, dynamic>?> _loadEggData(
      String nestId, String eggNr, int year) async {
    final eggRef = widget.firestore
        .collection(yearToNestCollectionName(year))
        .doc(nestId)
        .collection("egg")
        .doc("$nestId egg $eggNr");
    final snap = await eggRef.get();
    if (!snap.exists) {
      return null;
    }
    final data = Map<String, dynamic>.from(snap.data() as Map<String, dynamic>);
    data['_ref'] = eggRef;
    return data;
  }

  Future<String?> _loadPreviousEggStatus(
      String nestId, String eggNr, int year, String? currentStatus) async {
    final eggRef = widget.firestore
        .collection(yearToNestCollectionName(year))
        .doc(nestId)
        .collection("egg")
        .doc("$nestId egg $eggNr");
    final snap = await eggRef
        .collection("changelog")
        .orderBy(FieldPath.documentId, descending: true)
        .limit(6)
        .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    for (final doc in snap.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString();
      if (status.isEmpty) {
        continue;
      }
      if (currentStatus == null || status != currentStatus) {
        return status;
      }
    }
    return null;
  }

  Future<void> _moveChick() async {
    final band = _normalizeBand(_moveBandCntr.text);
    final targetNest = _moveNestCntr.text.trim();
    final targetEgg = _moveEggCntr.text.trim();
    if (band.isEmpty || targetNest.isEmpty || targetEgg.isEmpty) {
      _showMessage('Band, nest, and egg number are required.', isError: true);
      return;
    }
    if (_moveBusy) return;

    setState(() {
      _moveBusy = true;
    });

    try {
      final birdRef = widget.firestore.collection("Birds").doc(band);
      final birdSnap = await birdRef.get();
      if (!birdSnap.exists) {
        _showMessage('Bird $band not found.', isError: true);
        return;
      }

      final bird = Bird.fromDocSnapshot(birdSnap);
      if (!bird.ringed_as_chick) {
        _showMessage('Bird $band is not marked as a chick.', isError: true);
        return;
      }

      final oldNest = bird.nest?.trim() ?? '';
      final oldEgg = bird.egg?.trim() ?? '';
      final oldYear = bird.nest_year ?? bird.ringed_date.year;

      if (oldNest == targetNest &&
          oldEgg == targetEgg &&
          oldYear == _moveYear) {
        _showMessage('No changes detected.', isError: true);
        return;
      }

      final targetNestRef = widget.firestore
          .collection(yearToNestCollectionName(_moveYear))
          .doc(targetNest);
      final targetNestSnap = await targetNestRef.get();
      if (!targetNestSnap.exists) {
        _showMessage('Nest $targetNest not found for year $_moveYear.',
            isError: true);
        return;
      }

      final newEggData = await _loadEggData(targetNest, targetEgg, _moveYear);
      if (newEggData == null) {
        _showMessage(
            'Egg $targetEgg not found in nest $targetNest for year $_moveYear.',
            isError: true);
        return;
      }

      final newEggRing = (newEggData['ring'] ?? '').toString().trim();
      if (newEggRing.isNotEmpty && newEggRing != band) {
        _showMessage(
            'Target egg already has ring $newEggRing. Use swap or clear first.',
            isError: true);
        return;
      }

      Map<String, dynamic>? oldEggData;
      if (oldNest.isNotEmpty && oldEgg.isNotEmpty) {
        oldEggData = await _loadEggData(oldNest, oldEgg, oldYear);
        if (oldEggData == null) {
          _showMessage(
              'Previous egg $oldEgg not found in nest $oldNest (year $oldYear).',
              isError: true);
          return;
        }
      }

      final confirmed = await _confirmAction(
        'Move chick',
        'Move $band from nest $oldNest egg $oldEgg (year $oldYear) '
            'to nest $targetNest egg $targetEgg (year $_moveYear)? '
            'Old egg status will be restored from changelog and '
            'new egg status set to hatched.',
      );
      if (!confirmed) return;

      final now = DateTime.now();
      final nowId = now.toString();
      final user = _sps?.userName ?? (bird.responsible ?? 'unknown');

      final birdData =
          Map<String, dynamic>.from(birdSnap.data() as Map<String, dynamic>);
      birdData['nest'] = targetNest;
      birdData['nest_year'] = _moveYear;
      birdData['egg'] = targetEgg;
      birdData['last_modified'] = now;
      birdData['responsible'] = user;

      final batch = widget.firestore.batch();
      batch.set(birdRef, birdData);
      batch.set(birdRef.collection("changelog").doc(nowId),
          Map<String, dynamic>.from(birdData));

      if (oldEggData != null) {
        final oldEggRef = oldEggData['_ref'] as DocumentReference;
        final oldEggRing = (oldEggData['ring'] ?? '').toString().trim();
        if (oldEggRing.isNotEmpty && oldEggRing != band) {
          _showMessage(
              'Previous egg has ring $oldEggRing (expected $band). Move aborted.',
              isError: true);
          return;
        }
        final currentStatus = (oldEggData['status'] ?? '').toString();
        final prevStatus = await _loadPreviousEggStatus(
            oldNest, oldEgg, oldYear, currentStatus);
        oldEggData['ring'] = null;
        if (prevStatus != null) {
          oldEggData['status'] = prevStatus;
        }
        oldEggData['last_modified'] = now;
        oldEggData['responsible'] = user;
        batch.update(oldEggRef, {
          'ring': null,
          if (prevStatus != null) 'status': prevStatus,
          'last_modified': now,
          'responsible': user,
        });
        batch.set(oldEggRef.collection("changelog").doc(nowId),
            Map<String, dynamic>.from(oldEggData)..remove('_ref'));
      }

      final newEggRef = newEggData['_ref'] as DocumentReference;
      newEggData['ring'] = band;
      newEggData['status'] = 'hatched';
      newEggData['last_modified'] = now;
      newEggData['responsible'] = user;
      batch.update(newEggRef, {
        'ring': band,
        'status': 'hatched',
        'last_modified': now,
        'responsible': user,
      });
      batch.set(newEggRef.collection("changelog").doc(nowId),
          Map<String, dynamic>.from(newEggData)..remove('_ref'));

      await batch.commit();
      _showMessage('Move completed.');
    } catch (e) {
      _showMessage('Move failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _moveBusy = false;
        });
      }
    }
  }

  Future<void> _swapChicks() async {
    final bandA = _normalizeBand(_swapBandACntr.text);
    final bandB = _normalizeBand(_swapBandBCntr.text);
    if (bandA.isEmpty || bandB.isEmpty) {
      _showMessage('Both band values are required.', isError: true);
      return;
    }
    if (bandA == bandB) {
      _showMessage('Bands must be different.', isError: true);
      return;
    }
    if (_swapBusy) return;

    setState(() {
      _swapBusy = true;
    });

    try {
      final birdARef = widget.firestore.collection("Birds").doc(bandA);
      final birdBRef = widget.firestore.collection("Birds").doc(bandB);
      final birdASnap = await birdARef.get();
      final birdBSnap = await birdBRef.get();

      if (!birdASnap.exists || !birdBSnap.exists) {
        _showMessage('Both birds must exist.', isError: true);
        return;
      }

      final birdA = Bird.fromDocSnapshot(birdASnap);
      final birdB = Bird.fromDocSnapshot(birdBSnap);

      if (!birdA.ringed_as_chick || !birdB.ringed_as_chick) {
        _showMessage('Both birds must be marked as chicks.', isError: true);
        return;
      }

      final nestA = birdA.nest?.trim() ?? '';
      final eggA = birdA.egg?.trim() ?? '';
      final yearA = birdA.nest_year ?? birdA.ringed_date.year;

      final nestB = birdB.nest?.trim() ?? '';
      final eggB = birdB.egg?.trim() ?? '';
      final yearB = birdB.nest_year ?? birdB.ringed_date.year;

      if (nestA.isEmpty || nestB.isEmpty || eggA.isEmpty || eggB.isEmpty) {
        _showMessage('Both birds must have nest and egg numbers.',
            isError: true);
        return;
      }

      if (nestA == nestB && eggA == eggB && yearA == yearB) {
        _showMessage('Both birds reference the same egg.', isError: true);
        return;
      }

      if (yearA != yearB) {
        _showMessage('Swap across years is not supported.', isError: true);
        return;
      }

      final eggAData = await _loadEggData(nestA, eggA, yearA);
      final eggBData = await _loadEggData(nestB, eggB, yearB);
      if (eggAData == null || eggBData == null) {
        _showMessage('Both eggs must exist.', isError: true);
        return;
      }

      final eggARing = (eggAData['ring'] ?? '').toString().trim();
      final eggBRing = (eggBData['ring'] ?? '').toString().trim();
      if (eggARing.isNotEmpty && eggARing != bandA) {
        _showMessage('Egg $nestA/$eggA has ring $eggARing (expected $bandA).',
            isError: true);
        return;
      }
      if (eggBRing.isNotEmpty && eggBRing != bandB) {
        _showMessage('Egg $nestB/$eggB has ring $eggBRing (expected $bandB).',
            isError: true);
        return;
      }

      final confirmed = await _confirmAction(
        'Swap chicks',
        'Swap nest/egg assignments for $bandA and $bandB? '
            'Egg status is not changed.',
      );
      if (!confirmed) return;

      final now = DateTime.now();
      final nowId = now.toString();
      final user = _sps?.userName ?? 'unknown';

      final birdAData =
          Map<String, dynamic>.from(birdASnap.data() as Map<String, dynamic>);
      birdAData['nest'] = nestB;
      birdAData['nest_year'] = yearB;
      birdAData['egg'] = eggB;
      birdAData['last_modified'] = now;
      birdAData['responsible'] = user;

      final birdBData =
          Map<String, dynamic>.from(birdBSnap.data() as Map<String, dynamic>);
      birdBData['nest'] = nestA;
      birdBData['nest_year'] = yearA;
      birdBData['egg'] = eggA;
      birdBData['last_modified'] = now;
      birdBData['responsible'] = user;

      final batch = widget.firestore.batch();
      batch.set(birdARef, birdAData);
      batch.set(birdARef.collection("changelog").doc(nowId),
          Map<String, dynamic>.from(birdAData));
      batch.set(birdBRef, birdBData);
      batch.set(birdBRef.collection("changelog").doc(nowId),
          Map<String, dynamic>.from(birdBData));

      final eggARef = eggAData['_ref'] as DocumentReference;
      final eggBRef = eggBData['_ref'] as DocumentReference;

      eggAData['ring'] = bandB;
      eggAData['last_modified'] = now;
      eggAData['responsible'] = user;
      batch.update(eggARef, {
        'ring': bandB,
        'last_modified': now,
        'responsible': user,
      });
      batch.set(eggARef.collection("changelog").doc(nowId),
          Map<String, dynamic>.from(eggAData)..remove('_ref'));

      eggBData['ring'] = bandA;
      eggBData['last_modified'] = now;
      eggBData['responsible'] = user;
      batch.update(eggBRef, {
        'ring': bandA,
        'last_modified': now,
        'responsible': user,
      });
      batch.set(eggBRef.collection("changelog").doc(nowId),
          Map<String, dynamic>.from(eggBData)..remove('_ref'));

      await batch.commit();
      _showMessage('Swap completed.');
    } catch (e) {
      _showMessage('Swap failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _swapBusy = false;
        });
      }
    }
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, color: Colors.orange)),
          SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        decoration: InputDecoration(labelText: label, hintText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fix data links between birds, nests, and eggs. These tools '
                'update Firestore directly. Use with care.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 12),
              Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionHeader(
                          'Move chick to another nest/egg',
                          'Updates bird, removes ring from old egg, and '
                              'assigns ring to new egg. Egg status is changed.'),
                      _buildTextField(_moveBandCntr, 'Bird band'),
                      Row(
                        children: [
                          const Text('Year: '),
                          YearDropdown(
                            selectedYear: _moveYear,
                            onChanged: (int newValue) {
                              setState(() {
                                _moveYear = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      _buildTextField(_moveNestCntr, 'New nest ID'),
                      _buildTextField(_moveEggCntr, 'New egg number',
                          keyboardType: TextInputType.number),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _moveBusy ? null : _moveChick,
                        icon: _moveBusy
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.arrow_forward),
                        label: Text('Move chick'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionHeader(
                          'Swap two chicks',
                          'Swaps nest/egg assignments for two chicks. '
                              'Egg status is not changed.'),
                      _buildTextField(_swapBandACntr, 'Bird band A'),
                      _buildTextField(_swapBandBCntr, 'Bird band B'),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _swapBusy ? null : _swapChicks,
                        icon: _swapBusy
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.swap_horiz),
                        label: Text('Swap chicks'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
