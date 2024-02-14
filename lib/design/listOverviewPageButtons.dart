import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

SingleChildScrollView listOverviewPageButtons(BuildContext context) {
  //get the buttons for listExperiments, listNests, listBirds
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
      child:Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: <Widget>[
      ElevatedButton.icon(
        onPressed: ModalRoute.of(context)?.settings.name == "/listExperiments" ? null : () {
          Navigator.popAndPushNamed(context, "/listExperiments");
        },
        icon: Icon(
          Icons.science,
          color: ModalRoute.of(context)?.settings.name == "/listExperiments" ? Colors.green : Colors.black87,
          size: 25,
        ),
        label: Text("Experiments"),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white60),
        )
      ),
      ElevatedButton.icon(
        onPressed: ModalRoute.of(context)?.settings.name == "/listNests" ? null : () {
          //Navigator.popAndPushNamed(context, "/listNests");
        },
        icon: Icon(
          Icons.home,
          color: ModalRoute.of(context)?.settings.name == "/listNests" ? Colors.green : Colors.black87,
          size: 25,
        ),
        label: Text("Nests"),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white60),
          )
      ),
      ElevatedButton.icon(
        onPressed: ModalRoute.of(context)?.settings.name == "/listBirds" ? null : () {
          Navigator.popAndPushNamed(context, "/listBirds");
        },
        icon: SvgPicture.asset(
          'assets/icons/bird.svg',
          colorFilter: ColorFilter.mode(ModalRoute.of(context)?.settings.name == "/listBirds" ? Colors.green : Colors.black87, BlendMode.srcIn),
          height: 25,
          width: 25,
        ),
        label: Text("Birds"),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white60),
          )
      ),
    ],
  ));
}
