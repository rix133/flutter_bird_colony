import 'dart:math' as math;

import 'package:flutter_bird_colony/models/firestore/nest.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const double _earthRadiusMeters = 6378137.0;
const double _defaultOverlapDistanceMeters = 6.0;
const double _samePositionDistanceMeters = 0.05;

Map<String, LatLng> nudgedNestMarkerPositions(
  Iterable<Nest> nests, {
  double overlapDistanceMeters = _defaultOverlapDistanceMeters,
}) {
  final entries = nests
      .where((nest) => nest.id != null)
      .map((nest) => _NestMarkerPosition(nest))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  final positions = <String, LatLng>{
    for (final entry in entries) entry.id: entry.position,
  };

  for (final cluster in _overlapClusters(entries, overlapDistanceMeters)) {
    if (cluster.length < 2) {
      continue;
    }

    final center = _clusterCenter(cluster);
    final duplicateInfo = _duplicateInfo(cluster);
    final ringRadius = _ringRadiusMeters(cluster.length, overlapDistanceMeters);
    var fallbackAngleIndex = 0;

    for (final entry in cluster) {
      final accuracy = entry.nest.getAccuracy();
      if (accuracy <= 0 || accuracy.isNaN) {
        continue;
      }

      final nudgeDistance = math.min(accuracy, ringRadius);
      if (nudgeDistance <= 0) {
        continue;
      }

      final distanceFromCenter = latLngDistanceMeters(center, entry.position);
      var bearing = _bearingRadians(center, entry.position);
      final duplicates = duplicateInfo[entry]!;

      if (duplicates.count > 1) {
        final baseBearing =
            distanceFromCenter > _samePositionDistanceMeters ? bearing : 0.0;
        bearing =
            baseBearing + (2 * math.pi * duplicates.index / duplicates.count);
      } else if (distanceFromCenter <= _samePositionDistanceMeters) {
        bearing = 2 * math.pi * fallbackAngleIndex / cluster.length;
        fallbackAngleIndex++;
      }

      positions[entry.id] =
          _offsetLatLng(entry.position, nudgeDistance, bearing);
    }
  }

  return positions;
}

double latLngDistanceMeters(LatLng a, LatLng b) {
  final lat1 = _degreesToRadians(a.latitude);
  final lat2 = _degreesToRadians(b.latitude);
  final deltaLat = _degreesToRadians(b.latitude - a.latitude);
  final deltaLon = _degreesToRadians(b.longitude - a.longitude);

  final h = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(deltaLon / 2) *
          math.sin(deltaLon / 2);
  final clampedH = h.clamp(0.0, 1.0).toDouble();
  return _earthRadiusMeters *
      2 *
      math.atan2(math.sqrt(clampedH), math.sqrt(1 - clampedH));
}

List<List<_NestMarkerPosition>> _overlapClusters(
  List<_NestMarkerPosition> entries,
  double overlapDistanceMeters,
) {
  final parent = List<int>.generate(entries.length, (index) => index);

  int root(int index) {
    var current = index;
    while (parent[current] != current) {
      parent[current] = parent[parent[current]];
      current = parent[current];
    }
    return current;
  }

  void union(int a, int b) {
    final rootA = root(a);
    final rootB = root(b);
    if (rootA != rootB) {
      parent[rootB] = rootA;
    }
  }

  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      if (latLngDistanceMeters(entries[i].position, entries[j].position) <=
          overlapDistanceMeters) {
        union(i, j);
      }
    }
  }

  final clustersByRoot = <int, List<_NestMarkerPosition>>{};
  for (var i = 0; i < entries.length; i++) {
    clustersByRoot.putIfAbsent(root(i), () => []).add(entries[i]);
  }
  return clustersByRoot.values.toList();
}

LatLng _clusterCenter(List<_NestMarkerPosition> cluster) {
  final latitude = cluster
          .map((entry) => entry.position.latitude)
          .reduce((value, element) => value + element) /
      cluster.length;
  final longitude = cluster
          .map((entry) => entry.position.longitude)
          .reduce((value, element) => value + element) /
      cluster.length;
  return LatLng(latitude, longitude);
}

Map<_NestMarkerPosition, _DuplicateInfo> _duplicateInfo(
  List<_NestMarkerPosition> cluster,
) {
  final duplicateInfo = <_NestMarkerPosition, _DuplicateInfo>{};
  final assigned = <_NestMarkerPosition>{};

  for (final entry in cluster) {
    if (assigned.contains(entry)) {
      continue;
    }

    final duplicates = cluster
        .where((candidate) =>
            latLngDistanceMeters(entry.position, candidate.position) <=
            _samePositionDistanceMeters)
        .toList();

    for (var i = 0; i < duplicates.length; i++) {
      duplicateInfo[duplicates[i]] = _DuplicateInfo(i, duplicates.length);
      assigned.add(duplicates[i]);
    }
  }

  return duplicateInfo;
}

double _ringRadiusMeters(int clusterSize, double overlapDistanceMeters) {
  if (clusterSize <= 1) {
    return 0;
  }
  return overlapDistanceMeters / (2 * math.sin(math.pi / clusterSize));
}

double _bearingRadians(LatLng from, LatLng to) {
  final fromLat = _degreesToRadians(from.latitude);
  final toLat = _degreesToRadians(to.latitude);
  final deltaLon = _degreesToRadians(to.longitude - from.longitude);

  final y = math.sin(deltaLon) * math.cos(toLat);
  final x = math.cos(fromLat) * math.sin(toLat) -
      math.sin(fromLat) * math.cos(toLat) * math.cos(deltaLon);

  return math.atan2(y, x);
}

LatLng _offsetLatLng(LatLng position, double distanceMeters, double bearing) {
  final angularDistance = distanceMeters / _earthRadiusMeters;
  final lat = _degreesToRadians(position.latitude);
  final lon = _degreesToRadians(position.longitude);

  final offsetLat = math.asin(math.sin(lat) * math.cos(angularDistance) +
      math.cos(lat) * math.sin(angularDistance) * math.cos(bearing));
  final offsetLon = lon +
      math.atan2(
        math.sin(bearing) * math.sin(angularDistance) * math.cos(lat),
        math.cos(angularDistance) - math.sin(lat) * math.sin(offsetLat),
      );

  return LatLng(_radiansToDegrees(offsetLat), _radiansToDegrees(offsetLon));
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

double _radiansToDegrees(double radians) => radians * 180 / math.pi;

class _NestMarkerPosition {
  final Nest nest;

  _NestMarkerPosition(this.nest);

  String get id => nest.id!;

  LatLng get position =>
      LatLng(nest.coordinates.latitude, nest.coordinates.longitude);
}

class _DuplicateInfo {
  final int index;
  final int count;

  _DuplicateInfo(this.index, this.count);
}
