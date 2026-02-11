import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestoreFromChangelogDialog extends StatefulWidget {
  final DocumentReference itemRef;
  final String title;
  final String? subtitle;

  const RestoreFromChangelogDialog({
    super.key,
    required this.itemRef,
    required this.title,
    this.subtitle,
  });

  static Future<bool> show(
    BuildContext context, {
    required DocumentReference itemRef,
    required String title,
    String? subtitle,
  }) async {
    final restored = await showDialog<bool>(
      context: context,
      builder: (context) => RestoreFromChangelogDialog(
        itemRef: itemRef,
        title: title,
        subtitle: subtitle,
      ),
    );
    return restored ?? false;
  }

  @override
  State<RestoreFromChangelogDialog> createState() =>
      _RestoreFromChangelogDialogState();
}

class _ChangelogEntry {
  final String id;
  final Map<String, dynamic> data;
  final DateTime? lastModified;
  final bool isDeleted;

  _ChangelogEntry({
    required this.id,
    required this.data,
    required this.lastModified,
    required this.isDeleted,
  });
}

class _RestoreFromChangelogDialogState
    extends State<RestoreFromChangelogDialog> {
  late Future<List<_ChangelogEntry>> _entriesFuture;
  String? _restoringId;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<_ChangelogEntry>> _loadEntries() async {
    final snapshot = await widget.itemRef.collection('changelog').get();
    final entries = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      final lastModified = _extractDate(data['last_modified']) ??
          _parseDateFromId(doc.id);
      return _ChangelogEntry(
        id: doc.id,
        data: data,
        lastModified: lastModified,
        isDeleted: doc.id.startsWith('deleted_'),
      );
    }).toList();

    entries.sort((a, b) {
      final aDate = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return entries;
  }

  DateTime? _extractDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  DateTime? _parseDateFromId(String id) {
    final raw = id.startsWith('deleted_') ? id.substring('deleted_'.length) : id;
    return DateTime.tryParse(raw);
  }

  String _formatValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toString();
    }
    if (value is DateTime) {
      return value.toString();
    }
    if (value is GeoPoint) {
      return '${value.latitude}, ${value.longitude}';
    }
    if (value is DocumentReference) {
      return value.path;
    }
    if (value is Map) {
      final entries = value.entries
          .map((e) => '${e.key}: ${_formatValue(e.value)}')
          .join(', ');
      return '{ $entries }';
    }
    if (value is Iterable) {
      return '[${value.map(_formatValue).join(', ')}]';
    }
    return value?.toString() ?? '';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return date.toString();
  }

  Future<void> _viewEntry(_ChangelogEntry entry) async {
    final fields = entry.data.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Changelog snapshot'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                            '${entry.key}: ${_formatValue(entry.value)}'),
                      ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            onPressed: () {
              Navigator.pop(context);
              _restoreEntry(entry);
            },
            child: const Text('Restore',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreEntry(_ChangelogEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Restore version?'),
        content: const Text(
            'This will overwrite the current data with the selected version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _restoringId = entry.id;
    });

    try {
      final data = Map<String, dynamic>.from(entry.data);
      if (data.containsKey('last_modified')) {
        data['last_modified'] = DateTime.now();
      }
      await widget.itemRef.set(data);
      await widget.itemRef
          .collection('changelog')
          .doc(DateTime.now().toString())
          .set(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Restored selected version.'),
      ));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Restore failed: $error'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _restoringId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<_ChangelogEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Failed to load changelog: ${snapshot.error}');
            }
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return const Text('No changelog entries found.');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(widget.subtitle!),
                  ),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final subtitle = entry.isDeleted
                          ? 'Deleted snapshot'
                          : 'Saved snapshot';
                      final isRestoring = _restoringId == entry.id;
                      return ListTile(
                        title: Text(_formatDate(entry.lastModified)),
                        subtitle: Text(subtitle),
                        trailing: isRestoring
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                onPressed: () => _viewEntry(entry),
                                child: const Text('View'),
                              ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey,
          ),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Close'),
        )
      ],
    );
  }
}
