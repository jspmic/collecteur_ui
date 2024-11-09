import 'package:http/http.dart' as http;
import 'dart:convert';

// Address definition
const String HOST = "https://jspemic.pythonanywhere.com";
//const String HOST = "http://192.168.43.43:5000";

// GET methods session

Future<List> getTransfert(String date, String user) async {
  var url = Uri.parse("$HOST/api/transferts?date=$date&user=$user");
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

Future<List> getLivraison(String date, String user) async {
  var url = Uri.parse("$HOST/api/livraisons?date=$date&user=$user");
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

Future<bool> isUser(String _n_9032, String _n_9064) async {
  var CODE = "JK9X80L4RT";
  var url = Uri.parse(
      "$HOST/api/list?code=$CODE&_n_9032=$_n_9032&_n_9064=$_n_9064");
  http.Response response = await http.get(url);
  if (response.statusCode == 200) {
    return true;
  }
  return false;
}