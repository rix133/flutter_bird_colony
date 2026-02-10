import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/textFormItem.dart';
import 'package:flutter_bird_colony/models/firestore/firestoreItem.dart';
import 'package:flutter_bird_colony/models/firestoreItemMixin.dart';
import 'package:flutter_bird_colony/models/markerColorGroup.dart';
import 'package:flutter_bird_colony/models/updateResult.dart';
import 'package:flutter_bird_colony/services/sharedPreferencesService.dart';
import 'package:flutter_bird_colony/design/filledIconButton.dart';

class Species implements FirestoreItem {
  Species(
      {this.id,
      required this.english,
      required this.local,
      this.latin,
      required this.latinCode,
      this.responsible,
      this.last_modified,
      this.letters = ''});

  String? id;
  String local; //name in local langauge
  String english;
  String latinCode;
  DateTime? last_modified;
  String? latin;
  String letters;

  factory Species.empty() {
    return Species(
      english: '',
      local: '',
      latinCode: '',
    );
  }

  factory Species.fromEnglish(String english) {
    return Species(
      english: english,
      local: '',
      latinCode: '',
    );
  }

  factory Species.fromDocSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return Species(
      id: snapshot.id,
      english: data['english'] ?? '',
      local: data['local'] ?? '',
      latin: data['latin'],
      latinCode: data['latinCode'] ?? '',
      letters: data['letters'] ?? '',
    );
  }

  @override
  String toString() {
    return '$english, $local,$latinCode';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Species &&
        other.english == english &&
        other.local == local &&
        other.latinCode == latinCode;
  }

  String getBandLetters() {
    if (english == 'Common Gull') {
      return 'UA';
    }
    if (english == 'European Herring Gull') {
      return 'TA';
    }
    if (english == 'Lesser Black-backed Gull') {
      return 'L';
    }
    if (english == 'Great Black-backed Gull') {
      return 'L';
    }
    if (english == 'Common Tern') {
      return 'HK';
    }
    if (english == 'Arctic Tern') {
      return 'HK';
    }
    if (english == 'Great Cormorant') {
      return '';
    }
    if (english == 'Eurasian Oystercatcher') {
      return 'E';
    }
    if (english == 'Common Ringed Plover') {
      return 'PA';
    }
    if (english == 'Mute Swan') {
      return '';
    }
    if (english == 'Black-Headed Gull') {
      return '';
    }
    if (english == 'Greylag goose') {
      return '';
    }
    if (english == 'Mallard') {
      return '';
    }
    if (english == 'Little Gull') {
      return '';
    }
    return '';
  }

  @override
  int get hashCode => Object.hash(local, english, latinCode);

  @override
  String? responsible;

  @override
  DateTime get created_date => last_modified ?? DateTime(1900);

  @override
  Future<UpdateResult> delete(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      String type = "default"}) {
    if (id == null) {
      return Future.value(UpdateResult.deleteOK(item: this));
    }
    return (FSItemMixin().deleteFirestoreItem(this,
        firestore
            .collection('settings').doc(type).collection("species")));
  }

  @override
  String get name => local.isEmpty ? english : local;

  Species copy() {
    return Species(
      id: id,
      english: english,
      local: local,
      latin: latin,
      latinCode: latinCode,
      responsible: responsible,
      last_modified: last_modified,
      letters: letters,
    );
  }

  _saveChangeLog(FirebaseFirestore firestore, String type) {
    FSItemMixin().saveChangeLog(
        this, firestore.collection('settings').doc(type).collection('species'));
  }

  @override
  Future<UpdateResult> save(FirebaseFirestore firestore,
      {CollectionReference<Object?>? otherItems = null,
      bool allowOverwrite = false,
      String type = "default"}) {
    last_modified = DateTime.now();
    if (id == null) {
      return (firestore
          .collection('settings')
          .doc(type)
          .collection("species")
          .add(toJson())
          .then((value) {
        id = value.id;
        _saveChangeLog(firestore, type);
        return (UpdateResult.saveOK(item: this));
      }).catchError((error) => UpdateResult.error(message: error)));
    }
    return (firestore
        .collection('settings')
        .doc(type)
        .collection("species")
        .doc(id)
        .set(toJson())
        .then((value) {
      _saveChangeLog(firestore, type);
      return (UpdateResult.saveOK(item: this));
    }).catchError((error) => UpdateResult.error(message: error)));
  }

  @override
  List<TextCellValue> toExcelRowHeader() {
    return [
      TextCellValue('English'),
      TextCellValue('Local'),
      TextCellValue('Latin'),
      TextCellValue('Latin Code'),
      TextCellValue('Responsible'),
      TextCellValue("Letters"),
      TextCellValue("Last Modified"),
    ];
  }

  @override
  Future<List<List<CellValue>>> toExcelRows({List<FirestoreItem>? otherItems}) {
    return Future.value([
      [
        TextCellValue(english),
        TextCellValue(local),
        TextCellValue(latin ?? ''),
        TextCellValue(latinCode),
        TextCellValue(responsible ?? ''),
        TextCellValue(letters),
        DateTimeCellValue.fromDateTime(last_modified ?? DateTime.now()),
      ]
    ]);
  }

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      english: json['english'],
      local: json['local'] ?? '',
      latin: json['latin'] ?? '',
      latinCode: json['latinCode'] ?? '',
      responsible: json['responsible'] ?? '',
      letters: json['letters'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'local': local,
      'latin': latin,
      'latinCode': latinCode,
      'responsible': responsible,
      'letters': letters,
    };
  }

  List<UpdateResult> validate(SharedPreferencesService? sps,
      {List<FirestoreItem> otherItems = const []}) {
    return [];
  }

  List<Widget> getSpeciesForm(
      BuildContext context, void Function(Function()) setState) {
    return [
      TextFormItem(
          label: 'English',
          initialValue: english,
          changeFun: (value) => english = value),
      TextFormItem(
          label: 'Custom',
          initialValue: local,
          changeFun: (value) => local = value),
      TextFormItem(
          label: 'Latin',
          initialValue: latin ?? '',
          changeFun: (value) => latin = value),
      TextFormItem(
          label: 'Latin Code',
          initialValue: latinCode,
          changeFun: (value) => latinCode = value),
    ];
  }

  getDetailsDialog(BuildContext context, FirebaseFirestore firestore) {
    return AlertDialog(
      title: Text('Species details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('English: $english'),
          Text('Local: $local'),
          Text('Latin: ${latin ?? ''}'),
          Text('Latin Code: $latinCode'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('close'),
        ),
        //download changelog Elevated icon button
        ElevatedButton.icon(
          key: Key("downloadChangelog"),
          icon: Icon(Icons.download),
          label: Text("Download changelog"),
          onPressed: () async {
            Navigator.pop(context);
            await FSItemMixin().downloadChangeLog(
                this.changeLog(firestore), "species", firestore);
          },
        ),
      ],
    );
  }

  Widget getListTile(BuildContext context, FirebaseFirestore firestore,
      {bool disabled = false, List<MarkerColorGroup> groups = const []}) {
    return
      Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
        child: ListTile(
        title: Text(english + (latin != null ? ' (' + latin! + ')' : '')),
        subtitle: Text(local),
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return getDetailsDialog(context, firestore);
              });
        },
        trailing: FilledIconButton(
          icon: Icons.edit,
          iconColor: Colors.black,
          backgroundColor: Colors.white60,
          onPressed: () {
            Navigator.pushNamed(context, '/editSpecies', arguments: this);
          },
        ),
      ),
    );
  }

  @override
  Future<List<Species>> changeLog(FirebaseFirestore firestore) async {
    return (firestore
        .collection('settings')
        .doc('default')
        .collection('species')
        .doc(id)
        .collection('changeLog')
        .get()
        .then((value) {
      List<Species> speciesList =
          value.docs.map((e) => Species.fromDocSnapshot(e)).toList();
      speciesList.sort((a, b) => b.last_modified!.compareTo(
          a.last_modified!)); // Sort by last_modified in descending order
      return speciesList;
    }));
  }
}

class LocalSpeciesList {
  List<Species> species = <Species>[];

  LocalSpeciesList();

  factory LocalSpeciesList.example() {
    LocalSpeciesList list = LocalSpeciesList();
    List<Species> species = list.species;

    species.add(Species(
        english: 'Common Gull',
        local: 'Goéland cendré, Sturmmöwe, Stormmeeuw',
        latin: 'Larus canus',
        latinCode: 'larcan'));
    species.add(Species(
        english: 'Common Chaffinch',
        local: 'Pinson des arbres, Buchfink, Vink',
        latin: 'Fringilla coelebs',
        latinCode: 'fricoe'));
    species.add(Species(
        english: 'Common Wood Pigeon',
        local: 'Pigeon ramier, Ringeltaube, Houtduif',
        latin: 'Columba palumbus',
        latinCode: 'colpal'));
    species.add(Species(
        english: 'Dunnock',
        local: 'Accenteur mouchet, Heckenbraunelle, Heggemus',
        latin: 'Prunella modularis',
        latinCode: 'prumod'));
    species.add(Species(
        english: 'Common Blackbird',
        local: 'Merle noir, Amsel, Merel',
        latin: 'Turdus merula',
        latinCode: 'turmer'));
    species.add(Species(
        english: 'Eurasian Blue Tit',
        local: 'Mésange bleue, Blaumeise, Pimpelmees',
        latin: 'Cyanistes caeruleus',
        latinCode: 'cyacae'));
    species.add(Species(
        english: 'Great Tit',
        local: 'Mésange charbonnière, Kohlmeise, Koolmees',
        latin: 'Parus major',
        latinCode: 'parmaj'));
    species.add(Species(
        english: 'Eurasian Nuthatch',
        local: 'Sittelle torchepot, Kleiber, Boomklever',
        latin: 'Sitta europaea',
        latinCode: 'siteur'));
    species.add(Species(
        english: 'European Robin',
        local: 'Rouge-gorge familier, Rotkehlchen, Roodborst',
        latin: 'Erithacus rubecula',
        latinCode: 'erirub'));
    species.add(Species(
        english: 'Eurasian Tree Sparrow',
        local: 'Moineau friquet, Feldsperling, Ringmus',
        latin: 'Passer montanus',
        latinCode: 'pasmont'));
    species.add(Species(
        english: 'Common Starling',
        local: 'Étourneau sansonnet, Star, Spreeuw',
        latin: 'Sturnus vulgaris',
        latinCode: 'stuvul'));
    species.add(Species(
        english: 'Common Chiffchaff',
        local: 'Pouillot véloce, Zilpzalp, Tjiftjaf',
        latin: 'Phylloscopus collybita',
        latinCode: 'phocol'));
    species.add(Species(
        english: 'Willow Warbler',
        local: 'Pouillot fitis, Fitis, Fitis',
        latin: 'Phylloscopus trochilus',
        latinCode: 'photro'));
    species.add(Species(
        english: 'House Sparrow',
        local: 'Moineau domestique, Haussperling, Huismus',
        latin: 'Passer domesticus',
        latinCode: 'pasdom'));
    species.add(Species(
        english: 'Eurasian Sparrowhawk',
        local: 'Épervier d\'Europe, Sperber, Sperwer',
        latin: 'Accipiter nisus',
        latinCode: 'accnis'));
    species.add(Species(
        english: 'Common Buzzard',
        local: 'Buse variable, Mäusebussard, Buizerd',
        latin: 'Buteo buteo',
        latinCode: 'butbut'));
    species.add(Species(
        english: 'Eurasian Magpie',
        local: 'Pie bavarde, Elster, Ekster',
        latin: 'Pica pica',
        latinCode: 'picpic'));
    species.add(Species(
        english: 'Eurasian Coot',
        local: 'Foulque macroule, Blässhuhn, Meerkoet',
        latin: 'Fulica atra',
        latinCode: 'fulatr'));
    species.add(Species(
        english: 'Mallard',
        local: 'Canard colvert, Stockente, Wilde Eend',
        latin: 'Anas platyrhynchos',
        latinCode: 'anapla'));
    species.add(Species(
        english: 'Eurasian Skylark',
        local: 'Alouette des champs, Feldlerche, Veldleeuwerik',
        latin: 'Alauda arvensis',
        latinCode: 'alaarv'));
    species.add(Species(
        english: 'Common Swift',
        local: 'Martinet noir, Mauersegler, Gierzwaluw',
        latin: 'Apus apus',
        latinCode: 'apuapu'));
    species.add(Species(
        english: 'Common Kestrel',
        local: 'Faucon crécerelle, Turmfalke, Torenvalk',
        latin: 'Falco tinnunculus',
        latinCode: 'faltin'));
    species.add(Species(
        english: 'Common Linnet',
        local: 'Linotte mélodieuse, Bluthänfling, Kneu',
        latin: 'Linaria cannabina',
        latinCode: 'lincan'));
    species.add(Species(
        english: 'Carrion Crow',
        local: 'Corneille noire, Rabenkrahe, Zwarte Kraai',
        latin: 'Corvus corone',
        latinCode: 'corcor'));
    species.add(Species(
        english: 'Great Cormorant',
        local: 'Grand Cormoran, Kormoran, Aalscholver',
        latin: 'Phalacrocorax carbo',
        latinCode: 'phacar'));
    species.add(Species(
        english: 'Common Tern',
        local: 'Sterne pierregarin, Flussseeschwalbe, Visdief',
        latin: 'Sterna hirundo',
        latinCode: 'sterhi'));
    species.add(Species(
        english: 'Black-headed Gull',
        local: 'Mouette rieuse, Lachmöwe, Kokmeeuw',
        latin: 'Chroicocephalus ridibundus',
        latinCode: 'chreri'));
    species.add(Species(
        english: 'Lesser Black-backed Gull',
        local: 'Goéland brun, Heringsmöwe, Kleine Mantelmeeuw',
        latin: 'Larus fuscus',
        latinCode: 'larfus'));
    species.add(Species(
        english: 'Herring Gull',
        local: 'Goéland argenté, Silbermöwe, Zilvermeeuw',
        latin: 'Larus argentatus',
        latinCode: 'lararg'));
    species.add(Species(
        english: 'Yellow-legged Gull',
        local: 'Goéland leucophée, Mittelmeermöwe, Geelpootmeeuw',
        latin: 'Larus michahellis',
        latinCode: 'larmic'));
    species.add(Species(
        english: 'Caspian Gull',
        local: 'Goéland pontique, Steppenmöwe, Pontische Meeuw',
        latin: 'Larus cachinnans',
        latinCode: 'larcac'));
    species.add(Species(
        english: 'Iceland Gull',
        local: 'Goéland arctique, Polarmöwe, Kleine Burgemeester',
        latin: 'Larus glaucoides',
        latinCode: 'largla'));
    species.add(Species(
        english: 'Glaucous Gull',
        local: 'Goéland bourgmestre, Eismöwe, Grote Burgemeester',
        latin: 'Larus hyperboreus',
        latinCode: 'larhyp'));

    return list;
  }

  factory LocalSpeciesList.fromStringList(List<String> species) {
    LocalSpeciesList list = LocalSpeciesList();
    for (String specie in species) {
      list.species.add(Species(english: specie, local: '', latinCode: ''));
    }
    return list;
  }
  factory LocalSpeciesList.fromSpeciesList(List<Species> species) {
    LocalSpeciesList list = LocalSpeciesList();
    list.species = species;
    return list;
  }
  factory LocalSpeciesList.fromMap(Map<String, dynamic> json) {
    LocalSpeciesList list = LocalSpeciesList();
    json.forEach((key, value) {
      list.species.add(Species.fromJson(value));
    });
    return list;
  }

  Species getSp(Species? s) {
    if(s == null) {
      return Species.empty();
    }
    return species.firstWhere(
            (Species element) =>
        element.english.toLowerCase() == s.english.toLowerCase(),
        orElse: () => Species.empty());
  }

  Species getSpecies(String? english) {
    if(english == null) {
      return Species.empty();
    }
    return species.firstWhere(
            (Species element) =>
        element.english.toLowerCase() == english.toLowerCase(),
        orElse: () => Species.fromEnglish(english));
  }


}




