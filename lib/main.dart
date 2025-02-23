import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Collecteur/custom_widgets.dart';
import 'package:Collecteur/excel_fields.dart';
import 'package:Collecteur/rest.dart';
import 'package:Collecteur/populateScreen.dart';
import 'package:Collecteur/userScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xcel;

void main() async{
  await dotenv.load(fileName: ".env");
  await list(PROGRAM);
  runApp(const Collecteur());
}

DateTime? beginDate;
DateTime? endDate;

Transfert objTransfert = Transfert();
Livraison objLivraison = Livraison();

class Collecteur extends StatelessWidget {
  const Collecteur({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
          useMaterial3: true,
          primarySwatch: Colors.lightGreen),
      initialRoute: '/',
      routes: {
        "/populate": (context) => const Populate(),
        "/user": (context) => const addUser()
      },
      title: "Collecteur",
      home: const Interface(),
    );
  }
}

class Interface extends StatefulWidget {
  const Interface({super.key});

  @override
  State<Interface> createState() => _InterfaceState();
}

class _InterfaceState extends State<Interface> {
  String district = "";
  String program = "";
  bool isLoading = false;
  Color stateColor = Colors.black;
  Color stateColor2 = Colors.black;
  String stock = "";
  var user = TextEditingController();
  List? data;

  void storeTransfert() async{
    setState(() {
      stateColor = Colors.blue;
    });
    final xcel.Workbook workbook = xcel.Workbook();
    final xcel.Worksheet sheet = workbook.worksheets[0];
    sheet.getRangeByIndex(1, 1).setText("Date");
    sheet.getRangeByIndex(1, 2).setText("Plaque");
    sheet.getRangeByIndex(1, 3).setText("Logistic Official");
    sheet.getRangeByIndex(1, 4).setText("Numero du mouvement");
    sheet.getRangeByIndex(1, 5).setText("Stock Central Depart");
    sheet.getRangeByIndex(1, 6).setText("Succession des stocks");
    sheet.getRangeByIndex(1, 7).setText("Stock Central Retour");
    sheet.getRangeByIndex(1, 8).setText("Type de transport");
    sheet.getRangeByIndex(1, 9).setText("Motif");
    sheet.getRangeByIndex(1, 10).setText("Photo du mouvement");
    sheet.getRangeByIndex(1, 11).setText("Photo du journal du camion");
    DateFormat format = DateFormat("dd/MM/yyyy");
    for (var i = 0; i < collectedTransfert.length; i++) {
      final item = collectedTransfert[i];
      DateTime dateTime = format.parse(item.date);
      sheet.getRangeByIndex(i + 2, 1).setDateTime(dateTime);
      sheet.getRangeByIndex(i + 2, 2).setText(item.plaque);
      sheet.getRangeByIndex(i + 2, 3).setText(item.logistic_official);
      sheet.getRangeByIndex(i + 2, 4).setNumber(item.numero_mouvement.toDouble());//.setText(item.numero_mouvement.toString());
      sheet.getRangeByIndex(i + 2, 5).setText(formatStock(item.stock_central_depart));
      sheet.getRangeByIndex(i + 2, 6).setText(stockSuivantsControllers[item.id.toString()]!.text);
      sheet.getRangeByIndex(i + 2, 7).setText(formatStock(item.stock_central_retour));
      sheet.getRangeByIndex(i + 2, 8).setText(item.type_transport);
      sheet.getRangeByIndex(i + 2, 9).setText(item.motif);
      sheet.hyperlinks.add(sheet.getRangeByIndex(i + 2, 10), xcel.HyperlinkType.url, item.photo_mvt);
      sheet.hyperlinks.add(sheet.getRangeByIndex(i + 2, 11), xcel.HyperlinkType.url, item.photo_journal);
    }
    final List<int> bytes = workbook.saveAsStream();
    String date = "${beginDate?.day}-${beginDate?.month}-${beginDate?.year}";
    String now = DateFormat('hh:mm:ss a').format(DateTime.now());
    writeCounter("${user.text}_Transferts_du_${date}_$now.xlsx", bytes);
    workbook.dispose();
    setState(() {
      stateColor = Colors.green;
    });
  }

  void storeLivraison() async{
    int count = 2;
    setState(() {
      stateColor = Colors.blue;
    });
    final xcel.Workbook workbook = xcel.Workbook();
    final xcel.Worksheet sheet = workbook.worksheets[0];
    sheet.getRangeByIndex(1, 1).setText("Date");
    sheet.getRangeByIndex(1, 2).setText("Plaque");
    sheet.getRangeByIndex(1, 3).setText("Logistic Official");
    sheet.getRangeByIndex(1, 4).setText("Numero du mouvement");
    sheet.getRangeByIndex(1, 5).setText("Stock Central Depart");
    sheet.getRangeByIndex(1, 6).setText("Livraison ou Retour");
    sheet.getRangeByIndex(1, 7).setText("District");
    sheet.getRangeByIndex(1, 8).setText("Colline");
    sheet.getRangeByIndex(1, 9).setText("Produit");
    sheet.getRangeByIndex(1, 10).setText("Quantité");
    sheet.getRangeByIndex(1, 11).setText("Stock Central Retour");
    sheet.getRangeByIndex(1, 12).setText("Type de transport");
    sheet.getRangeByIndex(1, 13).setText("Motif");
    sheet.getRangeByIndex(1, 14).setText("Photo du mouvement");
    sheet.getRangeByIndex(1, 15).setText("Photo du journal du camion");
    DateFormat format = DateFormat("dd/MM/yyyy");
    for (var i = 0; i < collectedLivraison.length; i++) {
      for (String j in collectedLivraison[i].boucle.keys) {
        Livraison item = collectedLivraison[i];
        DateTime dateTime = format.parse(item.date);
        sheet.getRangeByIndex(i + count, 1).setDateTime(dateTime);
        sheet.getRangeByIndex(i + count, 2).setText(item.plaque);
        sheet.getRangeByIndex(i + count, 3).setText(item.logistic_official);
        sheet.getRangeByIndex(i + count, 4).setNumber(item.numero_mouvement
            .toDouble());
        sheet.getRangeByIndex(i + count, 5).setText(formatStock(item.stock_central_depart));
        sheet.getRangeByIndex(i + count, 6).setText(item.boucle[j]!["livraison_retour"]);
        sheet.getRangeByIndex(i + count, 7).setText(item.district);
        sheet.getRangeByIndex(i + count, 8).setText(item.boucle[j]!["colline"]);
        sheet.getRangeByIndex(i + count, 9).setText(item.boucle[j]!["input"]);
        String? quantite = item.boucle[j]!["quantite"];
        try {
          sheet.getRangeByIndex(i + count, 10).setNumber(
              quantite != null ? double.parse(quantite) : 0.0);
        }
        on FormatException {
          sheet.getRangeByIndex(i + count, 10).setNumber(0.0);
        }
        sheet.getRangeByIndex(i + count, 11).setText(formatStock(item.stock_central_retour));
        sheet.getRangeByIndex(i + count, 12).setText(item.type_transport);
        sheet.getRangeByIndex(i + count, 13).setText(item.motif);
        sheet.hyperlinks.add(
            sheet.getRangeByIndex(i + count, 14), xcel.HyperlinkType.url,
            item.photo_mvt);
        sheet.hyperlinks.add(
            sheet.getRangeByIndex(i + count, 15), xcel.HyperlinkType.url,
            item.photo_journal);
        count++;
      }
    }
    final List<int> bytes = workbook.saveAsStream();
    String date = "${beginDate?.day}-${beginDate?.month}-${beginDate?.year}";
    String now = DateFormat('hh:mm:ss a').format(DateTime.now());
    writeCounter("${user.text}-Livraison_du_${date}_$now.xlsx", bytes);
    workbook.dispose();
    setState(() {
      stateColor = Colors.green;
    });
  }

  void retrieve(String program, DateTime dateSelect1, DateTime? dateSelect2) async {
    String date = "${dateSelect1.day}/${dateSelect1.month}/${dateSelect1.year}";
    String? date2 = dateSelect2 != null ? "${dateSelect2.day}/${dateSelect2.month}/${dateSelect2.year}" : null;
    setState(() {
      isLoading = true;
    });
    program == "Transfert"
        ? await getTransfertFields(date, date2, user.text)
        : await getLivraisonFields(date, date2, user.text);
    setState(() {
      isLoading = false;
    });
  }

  void modifyMovement() async{
	  setState(() {
		  stateColor2 = Colors.blue;
	  });
	  bool status = program == "Transfert" ? await modifyTransfert() : await modifyLivraison();
	  if (status){
		  setState(() {
			stateColor2 = Colors.green;
		  });
	  }
	  else{
		  setState(() {
			stateColor2 = Colors.red;
		  });
	  }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        return (event.logicalKey == LogicalKeyboardKey.superKey)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: Scaffold(
          appBar: AppBar(
            title: ElevatedButton(onPressed: () => Navigator.pushNamed(context, "/user"),
            style: ElevatedButton.styleFrom(shadowColor: background, backgroundColor: background), child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset("assets/icon/drawer2.png",
                        fit: BoxFit.cover, width: 40, height: 40))),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DatePicker(placeHolder: "Date Début", onSelect: (begin_date){
                    beginDate = begin_date;
                  }),
                  DatePicker(placeHolder: "Date Fin", onSelect: (end_date){
                    endDate = end_date;
                  }),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      decoration: const InputDecoration(hintText: "Utilisateur"),
                      controller: user,
                    ),
                  ),
                  Stock(
                      hintText: "Program...",
                      column: PROGRAM,
                      background: background,
                      onSelect: (value) {
                        program = value;
                      }),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/populate");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white),
                      child: const Text("Remplir",
                        style: TextStyle(color: Colors.black))),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height / 15),
              program == "Transfert" ? transfertTable(date: formatDate(beginDate)!,
                dateFin: formatDate(endDate)) : livraisonTable(date: formatDate(beginDate).toString(),
                  dateFin: formatDate(endDate)),
              //: const Text("Pas de données", style: TextStyle(color: Colors.grey)),
              SizedBox(height: MediaQuery.of(context).size.height / 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  isLoading
                      ? const CircularProgressIndicator()
                      : IconButton(
                          onPressed: () {
                            if (beginDate != null) {
                              retrieve(program, beginDate!, endDate);
                            }
                            else{ return; }
                          },
						  icon: const Icon(Icons.import_export),
						  tooltip: "Récupérer les données",
						  color: Colors.black),
                  IconButton(
                      onPressed: () => program == "Transfert" ? storeTransfert() : storeLivraison(),
                      icon: const Icon(Icons.download_for_offline),
                      hoverColor: Colors.lightGreen,
                      tooltip: "Exporter les données",
                      color: stateColor),
                  IconButton(
                      onPressed: () => modifyMovement(),
                      //style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      icon: const Icon(Icons.upload),
                      hoverColor: Colors.blue,
                      tooltip: "Appliquer les changements",
                      color: stateColor2),

                  IconButton(
                      onPressed: () {
                        setState(() {
                          collectedTransfert = [];
                          collectedLivraison = [];
                          modifiedTransferts = {};
                          modifiedLivraisons = {};
                          stateColor = Colors.black;
                          stateColor2 = Colors.black;
                        });
                      },
                      icon: const Icon(Icons.clear_all_outlined),
                      hoverColor: Colors.red,
                      tooltip: "Vider le tableau",
                      color: Colors.black)
                ],
              )
            ]),
          )),
    );
  }
}
