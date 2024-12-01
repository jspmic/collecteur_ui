import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:collecteur/custom_widgets.dart';
import 'package:collecteur/excel_fields.dart';
import 'package:collecteur/rest.dart';
import 'package:flutter/material.dart';

class Populate extends StatefulWidget {
  const Populate({super.key});

  @override
  State<Populate> createState() => _PopulateState();
}

class _PopulateState extends State<Populate> {
  bool isLoading2 = false;
  bool isLoading3 = false;
  Color stateColor2 = Colors.black;
  Color stateColor3 = Colors.black;
  void deleteC() async{
    String code = dotenv.env["CODE"].toString();
	await deleteCollines(code);
  }
  void populateFields(bool collineEnabled) async{
    setState(() {
      collineEnabled ? isLoading3 = true : isLoading2 = true;
    });
    String code = dotenv.env["CODE"].toString();
    Worksheet workSheet = await Worksheet.fromAsset("assets/worksheet.xlsx");
    bool status = collineEnabled ? await populateCollines(workSheet, code) : await populate(workSheet, code);
    //bool status2 = await populateCollines(workSheet, code);
    if (status){
      collineEnabled ? stateColor3 = Colors.green : stateColor2 = Colors.green;
    }
    else{
      collineEnabled ? stateColor3 = Colors.red : stateColor2 = Colors.red;
    }
    setState(() {
      collineEnabled ? isLoading3 = false : isLoading2 = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
        colorScheme: background == Colors.white ? const ColorScheme.light(primary: Colors.lightGreen)
        : const ColorScheme.dark(primary: Colors.lightGreen),
    datePickerTheme: DatePickerThemeData(
    backgroundColor: background,
    dividerColor: Colors.lightGreen,
    )
    ),
    title: "Collecteur",
    home: Scaffold(
    backgroundColor: background,
    appBar: AppBar(
      title: BackButton(onPressed: () => Navigator.pop(context)),
    ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: (MediaQuery.of(context).size.height)/6),
              isLoading3 ? const CircularProgressIndicator() :
              ElevatedButton(onPressed: () => populateFields(true),
                  child: Text("Remplir les collines", style: TextStyle(color: stateColor3))),

              SizedBox(height: (MediaQuery.of(context).size.height)/6),

              isLoading2 ? const CircularProgressIndicator() :
              ElevatedButton(onPressed: () => populateFields(false), child: Text("Remplir d'autres colonnes", style: TextStyle(color: stateColor2))),
              SizedBox(height: (MediaQuery.of(context).size.height)/6),
              ElevatedButton(onPressed: () => deleteC(), child: const Text("Supprimer les colinnes", style: TextStyle(color: Colors.black)))
            ],
          ),
        ),
      )
    ));
  }
}
