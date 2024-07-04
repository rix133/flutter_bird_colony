import 'package:flutter/material.dart';


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
          hintText: kirjeldus,
        ),
      ),
      SizedBox(height: 10)
    ],
  );
}

