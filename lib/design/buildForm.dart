import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


//äkki kasutada TextField?
Widget buildForm(BuildContext context,String kirjeldus,[initialValue,controller, bool isNumber = false, Function(String)? submitFun = null, focus=null]){
  return new Column(
    children: <Widget>[
      TextFormField(
        // inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
        keyboardType: isNumber?TextInputType.number:TextInputType.text,
        controller: controller,
        textAlign: TextAlign.center,
        initialValue: initialValue,
        focusNode: focus,
        onFieldSubmitted: submitFun,
        decoration: InputDecoration(
          labelText: kirjeldus,
          labelStyle: TextStyle(color: Colors.yellow),
          hintText: kirjeldus,
          fillColor: Colors.orange,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: (BorderSide(
              color: Colors.indigo
            ))
          ),


          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(
              color: Colors.deepOrange,
              width: 1.5,
            ),
          ),
        ),
      ),
      SizedBox(height: 10)
    ],
  );
}

