import 'package:flutter/material.dart';

const Radius radius = Radius.circular(16.0);

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black87,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radius),
  ),
);
final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  foregroundColor: Colors.black87,
  backgroundColor: Colors.grey[300],
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radius),
  ),
);
final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: Colors.black87,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(radius),
  ),
);

final ListTileThemeData listTileTheme = ListTileThemeData(
  tileColor: Colors.grey[900], // background color of the ListTile
  iconColor: Colors.white,
  textColor: Colors.white,
  selectedColor: Colors.red, // color of the text when selected
  selectedTileColor: Colors.grey[700], // color of the tile when selected
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // shape of the tile
  contentPadding: EdgeInsets.symmetric(vertical:0, horizontal: 20), // padding inside the tile
  dense: true, // whether to compact the tile's layout
  horizontalTitleGap: 10, // horizontal gap between the leading and title
  minVerticalPadding: 5, // minimum vertical padding in the tile
  minLeadingWidth: 40, // minimum width of the leading widget
);

final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
  labelStyle: TextStyle(color: Colors.yellow),
  fillColor: Colors.orange,
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(25),
    borderSide: BorderSide(color: Colors.indigo),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(25.0),
    borderSide: BorderSide(
      color: Colors.deepOrange,
      width: 1.5,
    ),
  ),
);
