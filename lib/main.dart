import 'package:collecteur/custom_widgets.dart';
import 'package:collecteur/excel_fields.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Collecteur());
}

class Collecteur extends StatelessWidget {
  const Collecteur({super.key});

  @override
  Widget build(BuildContext context) {
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
  String stock = "";
  List? data;
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
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DatePicker(),
              Stock(hintText: "District", column: DISTRICT, background: background, onSelect: (value){
                setState(() {
                  district = value;
                });
              }),
              Stock(hintText: "Stock Central", column: STOCK_CENTRAL, background: background, onSelect: (value){
                setState(() {
                  stock = value;
                });
              }),
              Stock(hintText: "Program", column: PROGRAM, background: background, onSelect: (value){
                setState(() {
                  program = value;
                });
              }),
              ElevatedButton(onPressed: (){
                setState(() {
                  data = ["a"];
                });
              }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white), child: const Text("Exporter", style: TextStyle(color: Colors.black)))
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height/2),
          data != null ? Text("$district - $program - $stock") : Text("Pas de données")
        ],
      ),
    );
  }
}

