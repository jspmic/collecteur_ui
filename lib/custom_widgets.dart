import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:collecteur/excel_fields.dart';
import 'package:collecteur/rest.dart';

Map<int, Iterable<String?>> cache = {};
Map<String?, Iterable<String?>> cache2 = {};

var url = Uri.parse("$HOST/api/colline");
bool collineDisponible = false;
Color background = Colors.white;

// Function to list all the contents of the specified column in the sheet
void list(int column, {String? district}) async {
  Worksheet workSheet = await Worksheet.fromAsset("assets/worksheet.xlsx");
  if (district == null) {
    cache[column] = workSheet.readColumn("Feuille 1", column);
  } else {
    if (cache2.containsKey(district) == true) {
      return;
    }
    cache2[district] = workSheet.readColline("Feuille 1", district);
  }
}

void initialize({String? district}) {
  if (district != null) {
    list(DISTRICT + 5, district: district);
    return;
  }
  list(PROGRAM);
  list(DISTRICT);
}

// Custom DatePicker widget
class DatePicker extends StatefulWidget {
  final String placeHolder;
  final Function(DateTime?) onSelect;
  const DatePicker({super.key, required this.placeHolder, required this.onSelect});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _date;
  Future _selectDate(BuildContext context) async => showDatePicker(
              context: context,
              firstDate: DateTime(2005),
              lastDate: DateTime(2090),
              initialDate: DateTime.now())
          .then((DateTime? selected) {
        if (selected != null && selected != _date) {
          setState(() {
            _date = selected;
            widget.onSelect(_date);
          });
        }
      });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(backgroundColor: background),
              child: Text(
                _date == null
                    ? "${widget.placeHolder}..."
                    : "${_date?.day} / ${_date?.month} / ${_date?.year}",
                style: TextStyle(
                    color: background == Colors.white
                        ? Colors.black
                        : Colors.white),
              )),
        ],
      ),
    );
  }
}

// Function to return a drop-down of all the cell values in a column in the sheet
class Stock extends StatefulWidget {
  final String hintText;
  final int column;
  final String? district;
  final Color? background;
  final Function(String) onSelect;
  const Stock(
      {super.key,
      required this.hintText,
      required this.column,
      required this.background,
      this.district,
      required this.onSelect});

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  String _hintCopy = "Default";

  @override
  void initState() {
    _hintCopy = widget.hintText;
    super.initState();
    if (widget.district != null) {
      list(DISTRICT + 5, district: widget.district);
    } else {
      list(widget.column);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DropdownButton<String?>(
            items: (widget.district != null
                    ? cache2[widget.district]
                    : cache[widget.column])
                ?.map((choice) {
              return DropdownMenuItem(
                  value: choice, child: Text(choice.toString()));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _hintCopy = value!;
                widget.onSelect(value);
              });
            },
            hint: Text(_hintCopy,
                style: TextStyle(
                    color: widget.background == Colors.white
                        ? Colors.black
                        : Colors.white)),
            style: TextStyle(
                color: widget.background == Colors.white
                    ? Colors.black
                    : Colors.white)));
  }
}

String formatStock(String stock){
  return stock.replaceAll('_', ' ');
}

String printStockSuivants(Transfert objTransf){
  String result = "";
  for (String stock in objTransf.stock_central_suivants.values){
    result += "${formatStock(stock)} - ";
  }
  return result;
}

List<DataRow> _createTransfertRows() {
  List<Transfert> _data = List.from(collectedTransfert);
  return _data.map((e) {
    return DataRow(cells: [
      DataCell(Text(e.date.toString())),
      DataCell(Text(e.plaque.toString())),
      DataCell(Text(e.logistic_official.toString())),
      DataCell(Text(e.numero_mouvement.toString())),
      DataCell(Text(formatStock(e.stock_central_depart.toString()))),
      DataCell(Text(printStockSuivants(e))),
      DataCell(Text(formatStock(e.stock_central_retour.toString()))),
      DataCell(Text(e.type_transport.toString())),
      DataCell(Text(e.motif.toString())),
      DataCell(Text(e.photo_mvt.toString())),
      DataCell(Text(e.photo_journal.toString()))
    ]);
  }).toList();
}

List<DataRow> _createLivraisonRows() {
  List<Livraison> _data = List.from(collectedLivraison);
  List<DataRow> rows = [];
  _data.map((e){
    for (String l in e.boucle.keys) {
      DataRow row = DataRow(cells: [
      DataCell(Text(e.date.toString())),
          DataCell(Text(e.plaque.toString())),
          DataCell(Text(e.logistic_official.toString())),
          DataCell(Text(e.numero_mouvement.toString())),
          DataCell(Text(formatStock(e.stock_central_depart.toString()))),
          DataCell(Text(e.boucle[l]!["livraison_retour"].toString())),
        DataCell(Text(e.boucle[l]!["colline"].toString())),
        DataCell(Text(e.boucle[l]!["input"].toString())),
        DataCell(Text(e.boucle[l]!["quantite"].toString())),
          DataCell(Text(formatStock(e.stock_central_retour.toString()))),
          DataCell(Text(e.type_transport.toString())),
          DataCell(Text(e.motif.toString())),
          DataCell(Text(e.photo_mvt.toString())),
          DataCell(Text(e.photo_journal.toString()))
    ]);
      rows.add(row);
    }
  }).toList();
  return rows;
}

List<DataColumn> _createTransfertColumns() {
  return [
    const DataColumn(
        label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Plaque", style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Logistic Official",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Numero du mouvement",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Stock Central Depart",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Succession des stocks",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Stock Central Retour",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Type de transport",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Motif", style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Photo du mouvement",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Photo du journal",
            style: TextStyle(fontWeight: FontWeight.bold)))
  ];
}

List<DataColumn> _createLivraisonColumns() {
  return [
    const DataColumn(
        label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Plaque", style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Logistic Official",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Numero du mouvement",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Stock Central Depart",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Livraison ou Retour",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Colline",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Produit",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Quantité",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Stock Central Retour",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Type de transport",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Motif", style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Photo du mouvement",
            style: TextStyle(fontWeight: FontWeight.bold))),
    const DataColumn(
        label: Text("Photo du journal",
            style: TextStyle(fontWeight: FontWeight.bold)))
  ];
}

Widget transfertTable() {
  return SafeArea(
      child: SafeArea(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
          columns: _createTransfertColumns(), rows: _createTransfertRows()),
    ),
  ));
}

Widget livraisonTable() {
  return SafeArea(
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              columns: _createLivraisonColumns(), rows: _createLivraisonRows()),
        ),
      ));
}

Future<String> _getDst() async {
  final directory = await getApplicationDocumentsDirectory();

  // Create the parent directory if it doesn't exist
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return directory.path;
}

Future<File> _localFile(String fileName) async {
  final path = await _getDst();
  return File('$path\$fileName');
}

Future<File> writeCounter(String fileName, List<int> bytes) async {
  final file = await _localFile(fileName);

  // Write the file
  return file.writeAsBytes(bytes);
}
