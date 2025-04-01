import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/googleMapScreen.dart';

class EditDefaultMap extends GoogleMapScreen {
  const EditDefaultMap({Key? key, required auth})
      : super(key: key, auth: auth, autoUpdateLoc: false);

  @override
  _EditDefaultMapState createState() => _EditDefaultMapState();
}

class _EditDefaultMapState extends GoogleMapScreenState {
  @override
  GestureDetector lastFloatingButton() {
    return GestureDetector(
      child: FloatingActionButton(
        key: const Key("setDefaultLocation"),
        heroTag: "setDefaultLocation",
        onPressed: () async {
          Navigator.pop(context, camPosCurrent);
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
