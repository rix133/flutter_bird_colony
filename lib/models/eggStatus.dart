import 'package:flutter/material.dart';

class EggStatus {
  String status = "intact";

  EggStatus(this.status);

  @override
  String toString() {
    return status;
  }

  bool get canMeasure {
    return (status == "intact" ||
        status == "unknown" ||
        status == "small hole" ||
        status == "medium hole" ||
        status == "big hole" ||
        status == "crack" ||
        status == "dead egg");
  }

  Color? color() {
    return (status == "intact" || status == "unknown"
        ? Colors.green
        : (status == "broken" ||
                status == "missing" ||
                status == "predated" ||
                status == "drowned")
            ? Colors.red
            : Colors.orange[800]);
  }

  bool hasHatched() {
    return (status == "hatched" || status == "dead chick");
  }
}

class EggStatuses {
  static const List<String> statuses = [
    "intact",
    "predated",
    "crack",
    "broken",
    "missing",
    "unknown",
    "small hole",
    "medium hole",
    "big hole",
    "destroyed by human",
    "drowned",
    "hatched",
    "dead chick",
    "dead egg"
  ];
}
