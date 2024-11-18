import 'package:collecteur/custom_widgets.dart';
import 'package:collecteur/excel_fields.dart';
import 'package:collecteur/rest.dart';
import 'package:flutter/material.dart';

void main() {
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
      title: "Collecteur",
      home: Interface(),
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
  String stock = "";
  var user = TextEditingController();
  List? data;

  void retrieve(String program, DateTime dateSelect) async{
    String date = "${dateSelect.day}/${dateSelect.month}/${dateSelect.year}";
    setState(() {
      isLoading = true;
    });
    program == "Transfert" ? await getTransfertFields(date, user.text) : objLivraison;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset("assets/icon/drawer2.png",
              fit: BoxFit.cover, width: 40, height: 40),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                Stock(hintText: "Program...", column: PROGRAM, background: background, onSelect: (value){
                  setState(() {
                    program = value;
                  });
                }),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height/15),
              program == "Transfert" ? SingleChildScrollView(child: transfertTable()) : const Text("Pas de donnees", style: TextStyle(color: Colors.grey)),
            SizedBox(height: MediaQuery.of(context).size.height/2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: () {
                    retrieve(program, dateSelected!);
                  },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      child: const Text("Exporter", style: TextStyle(color: Colors.black))),
                            ElevatedButton(onPressed: (){
                              setState(() {
                                collectedTransfert = [];
                              });
                            },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text("Clear", style: TextStyle(color: Colors.black))),
                ],
              )
              ]),
      )
    );
  }
}

