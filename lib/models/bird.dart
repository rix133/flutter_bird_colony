
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakrarahu/models/firestore_item.dart';
import 'package:kakrarahu/models/measure.dart';

class Bird implements FirestoreItem{
  String? id;
  String? nest;
  String? age;
  String band;
  String? color_band;
  String? responsible;
  String? species;
  DateTime ringed_date;
  String? egg;
  List<Measure> measures = [];

  @override
  String get name => color_band ?? band;

  Bird({this.id,
    required this.ringed_date,
    required this.band,
    this.color_band,
    this.responsible,
    this.species,
    this.age,
    this.nest,
    this.egg,
    required this.measures});




  bool timeSpan(String range){
    if(range == "All"){return(true);}
    if(range == "Today"){
      var today = DateTime.now().toIso8601String().split("T")[0];
      return this.ringed_date.toIso8601String().split("T")[0].toString() == today;
    }
    return false;
  }
  bool people(String range, String me){
    if(range == "Everybody"){return(true);}
    if(range == "Me"){
      return this.responsible == me;
    }
    return false;
  }

  @override
  factory Bird.fromQuerySnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> json = snapshot.data() as Map<String, dynamic>;
    return (Bird(
      id: snapshot.id,
      ringed_date: (json['ringed_date'] as Timestamp).toDate(),
      band: json["band"] ?? '',
      color_band: json["color_band"] ?? null,
      responsible: json["responsible"] ?? null,
      egg: json['egg'] ?? null,
      species: json['species'] ?? null,
      nest: json['nest'] ?? null,
      age: json['age'] ?? null,
      measures: (json['measures'] as List<dynamic>?)?.map((e) => measureFromJson(e)).toList() ?? [], // provide a default value if 'measures' does not exist
    ));
  }

  Map<String, dynamic> toJson() {
    return {
      'ringed_date': ringed_date,
      'band': band,
      'color_band': color_band,
      'responsible': responsible,
      'species': species,
      'nest': nest,
      'age': age,
      'egg': egg,
      'measures': measures.map((e) => e.toJson()).toList(),
    };
  }

  Future<bool> _write2Firestore(CollectionReference birds, CollectionReference nestsItemCollection,  bool isParent) async {
      // take ony those measures where value is not empty
      measures = measures.where((element) => element.value.isNotEmpty).toList();

      return(await birds.doc(band).set(toJson())
            .whenComplete(() => birds
            .doc(band)
            .collection("changelog")
            .doc(DateTime.now().toString())
            .set(toJson()))
            .whenComplete(() => (nest?.isEmpty ?? true) ? true : nestsItemCollection
            .doc(isParent ? band : "$nest egg $egg")
            .set(isParent ? toJson() : {'ring': band, 'status':'hatched'})).then((value) => true).catchError((error) => false));

  }

  @override
  Future <bool> save({CollectionReference<Object?>? otherItems = null, bool allowOverwrite = false, type = "parent"}) async {
    if(band.isEmpty){
      return false;
    }
    if(type == "parent" || type == "chick"){
      CollectionReference birds = FirebaseFirestore.instance.collection("Birds");
      bool isParent = (type == "parent");
      if(allowOverwrite && otherItems != null){
        return await _write2Firestore(birds, otherItems, isParent);
      } else if (otherItems != null){
        return await birds.doc(band).get().then((value) {
          if (!value.exists) {
            return _write2Firestore(birds, otherItems, isParent);
          } else{
            return false;
          }
        });
      }
    }
    throw UnimplementedError();
  }

  @override
  Future <bool> delete({CollectionReference<Object?>? otherItems = null, bool soft=true, type="parent"}) async {
  // delete from the nest as well if asked for
  if(otherItems != null){
    await otherItems.doc(id).delete().then((value) => true).catchError((error) => false);
  }
  CollectionReference items = FirebaseFirestore.instance.collection("Birds");
  if(!soft){
    return await items.doc(id).delete().then((value) => true).catchError((error) => false);
  } else{
    CollectionReference deletedCollection = FirebaseFirestore.instance.collection("deletedItems").doc("Birds").collection("deleted");

    //check if the item is already in deleted collection
    return deletedCollection.doc(id).get().then((doc) {
      if(doc.exists == false) {
        return deletedCollection.doc(id).set(toJson()).then((value) =>
            items.doc(id).delete().then((value) => true)).catchError((error) => false);
      } else {
        return deletedCollection.doc('${id}_${DateTime.now().toString()}').set(toJson()).then((value) =>
            items.doc(id).delete().then((value) => true)).catchError((error) => false);
      }
    }).catchError((error) => false);
  }
}

}
