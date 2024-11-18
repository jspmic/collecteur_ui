import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Address definition
const String HOST = "https://jspemic.pythonanywhere.com";
// const String HOST = "http://localhost:5000";

// Object fill up
List<Transfert> collectedTransfert = [];

class Transfert{
  String date = "";
  String plaque = "";
  String logistic_official = "";
  int numero_mouvement = 0;
  String stock_central_depart = "";
  Map<String, dynamic> stock_central_suivants = {};
  String stock_central_retour = "";
  String photo_mvt = "";
  String type_transport = "";
  String user = "";
  String? motif = "";
  Transfert();
}

class Livraison{
  late String date;
  late String plaque;
  late String logistic_official;
  late String numero_mouvement;
  late String district;
  late String stock_central_depart;
  late Map<String, Map<String, String>> boucle = {};
  late String stock_central_retour;
  String photo_mvt = "";
  late String type_transport;
  late String user;
  late String? motif;
  Livraison();
}

Future<int> getTransfertFields(String date, String user) async{
  assert(date != "" && user != "");
  collectedTransfert = [];
  List data = await getTransfert(date, user).timeout(const Duration(seconds: 40));
  for (Map<String, dynamic> mouvement in data){
    Transfert objTransfert = Transfert();
    objTransfert.date = mouvement["date"];
    objTransfert.plaque = mouvement["plaque"];
    objTransfert.logistic_official = mouvement["logistic_official"];
    objTransfert.numero_mouvement = (mouvement["numero_mouvement"]) as int;
    objTransfert.stock_central_depart = mouvement["stock_central_depart"];
    objTransfert.stock_central_suivants = mouvement["stock_central_suivants"];
    objTransfert.stock_central_retour = mouvement["stock_central_retour"];
    objTransfert.photo_mvt = mouvement["photo_mvt"];
    objTransfert.type_transport = mouvement["type_transport"];
    objTransfert.motif = mouvement["motif"];
    collectedTransfert.add(objTransfert);
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
  }
  on http.ClientException{
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
  }
  on http.ClientException{
    return [];
  }
}

Future<bool> isUser(String _n_9032, String _n_9064) async {
  await dotenv.load(fileName: ".env");
  String code = dotenv.env["CODE"].toString();
  var url = Uri.parse("$HOST/api/list");
  try{
    http.Response response = await http.get(url,
        headers: {"x-api-key": code,
          "Authorization": "$_n_9032:$_n_9064"}
    ).timeout(Duration(seconds: 30), onTimeout: (){
      return http.Response("No connection", 404);
    });
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
  on http.ClientException{
    return false;
  }
}