import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:collecteur/custom_widgets.dart';
import 'package:collecteur/excel_fields.dart';
import 'package:collecteur/rest.dart';
import 'package:collecteur/populateScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xcel;

void main() async{
  await dotenv.load(fileName: ".env");
  initialize();
  runApp(const Collecteur());
}

Transfert objTransfert = Transfert();
Livraison objLivraison = Livraison();

class Collecteur extends StatelessWidget {
  const Collecteur({super.key});

  @override
  Widget build(BuildContext context) {
    initialize();
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
          useMaterial3: true,
          primarySwatch: Colors.lightGreen),
      initialRoute: '/',
      routes: {
        "/populate": (context) => const Populate()
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
      sheet.getRangeByIndex(i + 2, 6).setText(printStockSuivants(item));
      sheet.getRangeByIndex(i + 2, 7).setText(formatStock(item.stock_central_retour));
      sheet.getRangeByIndex(i + 2, 8).setText(item.type_transport);
      sheet.getRangeByIndex(i + 2, 9).setText(item.motif);
      sheet.hyperlinks.add(sheet.getRangeByIndex(i + 2, 10), xcel.HyperlinkType.url, item.photo_mvt);
      sheet.hyperlinks.add(sheet.getRangeByIndex(i + 2, 11), xcel.HyperlinkType.url, item.photo_journal);
    }
    final List<int> bytes = workbook.saveAsStream();
    String date = "${dateSelected?.day}-${dateSelected?.month}-${dateSelected?.year}";
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
    sheet.getRangeByIndex(1, 7).setText("Colline");
    sheet.getRangeByIndex(1, 8).setText("Produit");
    sheet.getRangeByIndex(1, 9).setText("Quantité");
    sheet.getRangeByIndex(1, 10).setText("Stock Central Retour");
    sheet.getRangeByIndex(1, 11).setText("Type de transport");
    sheet.getRangeByIndex(1, 12).setText("Motif");
    sheet.getRangeByIndex(1, 13).setText("Photo du mouvement");
    sheet.getRangeByIndex(1, 14).setText("Photo du journal du camion");
    DateFormat format = DateFormat("dd/MM/yyyy");
    for (var i = 0; i < collectedLivraison.length; i++) {
      for (String j in collectedLivraison[i].boucle.keys) {
        var item = collectedLivraison[i];
        DateTime dateTime = format.parse(item.date);
        sheet.getRangeByIndex(i + count, 1).setDateTime(dateTime);
        sheet.getRangeByIndex(i + count, 2).setText(item.plaque);
        sheet.getRangeByIndex(i + count, 3).setText(item.logistic_official);
        sheet.getRangeByIndex(i + count, 4).setNumber(item.numero_mouvement
            .toDouble());
        sheet.getRangeByIndex(i + count, 5).setText(formatStock(item.stock_central_depart));
        sheet.getRangeByIndex(i + count, 6).setText(item.boucle[j]!["livraison_retour"]);
        sheet.getRangeByIndex(i + count, 7).setText(item.boucle[j]!["colline"]);
        sheet.getRangeByIndex(i + count, 8).setText(item.boucle[j]!["input"]);
        sheet.getRangeByIndex(i + count, 9).setText(item.boucle[j]!["quantite"]);
        sheet.getRangeByIndex(i + count, 10).setText(formatStock(item.stock_central_retour));
        sheet.getRangeByIndex(i + count, 11).setText(item.type_transport);
        sheet.getRangeByIndex(i + count, 12).setText(item.motif);
        sheet.hyperlinks.add(
            sheet.getRangeByIndex(i + count, 13), xcel.HyperlinkType.url,
            item.photo_mvt);
        sheet.hyperlinks.add(
            sheet.getRangeByIndex(i + count, 14), xcel.HyperlinkType.url,
            item.photo_journal);
        count++;
      }
    }
    final List<int> bytes = workbook.saveAsStream();
    String date = "${dateSelected?.day}-${dateSelected?.month}-${dateSelected?.year}";
    String now = DateFormat('hh:mm:ss a').format(DateTime.now());
    writeCounter("${user.text}_Livraison_du_${date}_$now.xlsx", bytes);
    workbook.dispose();
    setState(() {
      stateColor = Colors.green;
    });
  }

  void retrieve(String program, DateTime dateSelect) async {
    String date = "${dateSelect.day}/${dateSelect.month}/${dateSelect.year}";
    setState(() {
      isLoading = true;
    });
    program == "Transfert"
        ? await getTransfertFields(date, user.text)
        : await getLivraisonFields(date, user.text);
    setState(() {
      isLoading = false;
    });
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
            title: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset("assets/icon/drawer2.png",
                  fit: BoxFit.cover, width: 40, height: 40),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const DatePicker(),
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
              program != ""
                  ? program == "Transfert" ? SingleChildScrollView(child: transfertTable()) : SingleChildScrollView(child: livraisonTable())
              : const Text("Pas de données", style: TextStyle(color: Colors.grey)),
              SizedBox(height: MediaQuery.of(context).size.height / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            retrieve(program, dateSelected!);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white),
                          child: const Text("Générer",
                              style: TextStyle(color: Colors.black))),
                  ElevatedButton(
                      onPressed: () => program == "Transfert" ? storeTransfert() : storeLivraison(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      child: Text("Conserver",
                          style: TextStyle(color: stateColor))),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          collectedTransfert = [];
                          collectedLivraison = [];
                          stateColor = Colors.black;
                        });
                      },
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      child: const Text("Nettoyer",
                          style: TextStyle(color: Colors.black))),
                ],
              )
            ]),
          )),
    );
  }
}
