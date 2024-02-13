import 'package:flutter/material.dart';




Widget buildButton(String buttonTitle,BuildContext context,[String? navigateTo,IconData? icon,updateLocation]) {
  final Color tintColor = Colors.orange;


  double Size=0;
  if(icon!=null){Size=40;}
  Icon iconadder= new Icon(icon, color: tintColor, size: Size,);

  return new Column(
    children: <Widget>[
      iconadder,
      new ElevatedButton(
        onPressed: () => {
          Navigator.pushNamed(context,navigateTo!,arguments: "T"),
        },
        child: new Text(buttonTitle,
            style: new TextStyle(
          fontSize: 32.0, fontWeight: FontWeight.w700,)),
      ),
      SizedBox(height: 10),


    ],
  );
}
