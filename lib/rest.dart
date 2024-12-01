import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'excel_fields.dart';
import 'dart:convert';

// Address definition
String HOST = dotenv.env["HOST"].toString();

// Object fill up
List<Transfert> collectedTransfert = [];
List<Livraison> collectedLivraison = [];

class Transfert {
  String date = "";
  String plaque = "";
  String logistic_official = "";
  int numero_mouvement = 0;
  String stock_central_depart = "";
  Map<String, dynamic> stock_central_suivants = {};
  String stock_central_retour = "";
  String photo_mvt = "";
  String photo_journal = "";
  String type_transport = "";
  String user = "";
  String? motif = "";
  Transfert();
  List<Map> toDict() {
    Map stock_svt = Map.from(stock_central_suivants);
    return [
      {
        "date": date,
        "plaque": plaque,
        "Logistic Official": logistic_official,
        "Numero du mouvement": numero_mouvement,
        "Stock Central Depart": stock_central_depart,
        "Stock Central Suivants": stock_svt.keys.map((e){
          return stock_central_suivants[e];
        }).toList(),
        "Stock Central Retour": stock_central_retour,
        "Photo du mouvement": photo_mvt,
        "Photo du journal": photo_journal,
        "Type de transport": type_transport,
        "Motif": motif
      }
    ];
  }
}

class Livraison {
  late String date;
  late String plaque;
  late String logistic_official;
  late int numero_mouvement;
  late String district;
  late String stock_central_depart;
  //Map<String, Map<String, String>> boucle = {};
  Map<String, dynamic> boucle = {};
  late String stock_central_retour;
  String photo_mvt = "";
  String photo_journal = "";
  late String type_transport;
  late String user;
  late String? motif;
  Livraison();
  List<Map> toDict() {
    return [
      {
        "date": date,
        "plaque": plaque,
        "Logistic Official": logistic_official,
        "Numero du mouvement": numero_mouvement,
        "Stock Central Depart": stock_central_depart,
        "Stock Central Retour": stock_central_retour,
        "Photo du mouvement": photo_mvt,
        "Photo du journal": photo_journal,
        "Type de transport": type_transport,
        "Motif": motif
      }
    ];
  }
}

Future<int> getTransfertFields(String date, String user) async {
  collectedTransfert = [];
  List data =
      await getTransfert(date, user).timeout(const Duration(seconds: 40));
  for (Map<String, dynamic> mouvement in data) {
    Transfert objTransfert = Transfert();
    objTransfert.date = mouvement["date"];
    objTransfert.plaque = mouvement["plaque"];
    objTransfert.logistic_official = mouvement["logistic_official"];
    objTransfert.numero_mouvement = (mouvement["numero_mouvement"]) as int;
    objTransfert.stock_central_depart = mouvement["stock_central_depart"];
    objTransfert.stock_central_suivants = mouvement["stock_central_suivants"];
    objTransfert.stock_central_retour = mouvement["stock_central_retour"];
    objTransfert.photo_mvt = mouvement["photo_mvt"];
    objTransfert.photo_journal = mouvement["photo_journal"];
    objTransfert.type_transport = mouvement["type_transport"];
    objTransfert.motif = mouvement["motif"];
    collectedTransfert.add(objTransfert);
  }
  return 0;
}

Future<int> getLivraisonFields(String date, String user) async {
  collectedLivraison = [];
  List data = await getLivraison(date, user).timeout(const Duration(seconds: 40));
  for (Map<String, dynamic> mouvement in data) {
    Livraison objLivraison= Livraison();
    objLivraison.date = mouvement["date"];
    objLivraison.plaque = mouvement["plaque"];
    objLivraison.logistic_official = mouvement["logistic_official"];
    objLivraison.numero_mouvement = (mouvement["numero_mouvement"]) as int;
    objLivraison.stock_central_depart = mouvement["stock_central_depart"];
    objLivraison.boucle = mouvement["boucle"];
    objLivraison.stock_central_retour = mouvement["stock_central_retour"];
    objLivraison.photo_mvt = mouvement["photo_mvt"];
    objLivraison.photo_journal = mouvement["photo_journal"];
    objLivraison.type_transport = mouvement["type_transport"];
    objLivraison.motif = mouvement["motif"];
    collectedLivraison.add(objLivraison);
  }
  return 0;
}

// GET methods session

Future<List> getTransfert(String date, String user) async {
  var url = Uri.parse("$HOST/api/transferts?date=$date&user=$user");
  try {
    http.Response response = await http.get(url);
    var decoded = [];
    if (response.statusCode == 200) {
      String data = response.body;
      decoded = jsonDecode(data);
    } else {
      decoded = [];
    }
    return decoded;
  } on http.ClientException {
    return [];
  }
}

Future<List> getLivraison(String date, String user) async {
  var url = Uri.parse("$HOST/api/livraisons?date=$date&user=$user");
  try {
    http.Response response = await http.get(url);
    var decoded = [];
    if (response.statusCode == 200) {
      String data = response.body;
      decoded = jsonDecode(data);
    } else {
      decoded = [];
    }
    return decoded;
  } on http.ClientException {
    return [];
  }
}

Future<bool> isUser(String _n_9032, String _n_9064) async {
  String code = dotenv.env["CODE"].toString();
  var url = Uri.parse("$HOST/api/list");
  try {
    http.Response response = await http.get(url, headers: {
      "x-api-key": code,
      "Authorization": "$_n_9032:$_n_9064"
    }).timeout(const Duration(seconds: 30), onTimeout: () {
      return http.Response("No connection", 404);
    });
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  } on http.ClientException {
    return false;
  }
}

Future<bool> populate(Worksheet workSheet, String code) async {
  List<String?> districts = workSheet.readColumn("Feuille 1", DISTRICT);
  List<String?> typeTransports = workSheet.readColumn("Feuille 1", TYPE_TRANSPORT);
  List<String?> stocks = workSheet.readColumn("Feuille 1", STOCK_CENTRAL);
  List<String?> inputs = workSheet.readColumn("Feuille 1", INPUT);
  var url = Uri.parse("$HOST/api/populate");
	var bodyContent = jsonEncode(<String, String>{
		"districts": jsonEncode(districts),
		"type_transports": jsonEncode(typeTransports),
		"stocks": jsonEncode(stocks),
		"inputs": jsonEncode(inputs)
	});
  try {
    http.Response response = await http.post(url, headers: {
			"x-api-key": code,
			'Content-Type': 'application/json; charset=UTF-8'
		},
	body: bodyContent).timeout(const Duration(seconds: 60), onTimeout: () {
      return http.Response("No connection", 404);
    });
    if (response.statusCode == 201) {
      return true;
    }
    return false;
  } on Exception {
    return false;
  }
}

Future<bool> populateCollines(Worksheet workSheet, String code) async {
  List<String?> districts = workSheet.readColumn("Feuille 1", DISTRICT);
  districts = districts.sublist(1);
  var url = Uri.parse("$HOST/api/colline");
  http.Response? response;
  //List<String?> collines = [];
  for (var district in districts) {
	String? collines = jsonEncode(workSheet.readColline("Feuille 1", district));
    response = await http.post(url, headers: {
      "x-api-key": code,
      'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          "district": district,
          "collines": collines
        })).timeout(const Duration(minutes: 2), onTimeout: () {
      return http.Response("No connection", 404);
    });
	}
    try {
      if (response!.statusCode == 201) {
        return true;
      }
      return false;
    } on Exception {
      return false;
    }
  }

Future<bool> deleteCollines(String code) async{
	var url = Uri.parse("$HOST/api/colline");
	http.Response response;
	response = await http.delete(url, headers: {
	  "x-api-key": code,
	  'Content-Type': 'application/json; charset=UTF-8'});
	return response.statusCode == 200;
}
