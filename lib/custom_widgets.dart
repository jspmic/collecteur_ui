import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:Collecteur/excel_fields.dart';
import 'package:Collecteur/rest.dart';

Map<int, Iterable<String?>> cache = {};
Map<String?, Iterable<String?>> cache2 = {};

var url = Uri.parse("$HOST/api/colline");
bool collineDisponible = false;
Color background = Colors.white;

// Function to list all the contents of the specified column in the sheet
Future<void> list(int column, {String? district}) async {
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

Map<String, Map<String, dynamic>> modifiedLivraisons = {};
Map<String, Map<String, dynamic>> modifiedTransferts = {};

// These two functions save particular fields of a Livraison or Transfert
void saveBoucle(String id, String boucleId, String columnName, String newValue){
	Livraison concernedLivraison = collectedLivraison[id as int];

	// Making a copy of the `boucle` to not overwrite it by mistake
	Map<String, dynamic> boucle = concernedLivraison.boucle;
	boucle[boucleId][columnName] = newValue;
	modifiedLivraisons[id] = {"boucle": jsonEncode(boucle)};
}

// This function saves a certain movement to the new content
void saveModified(String movement, String id, Map<String, String> content, {int? boucleId}){
  if (movement == "Livraison"){
	modifiedLivraisons.containsKey(id) ? modifiedLivraisons[id]!.addAll(content)
	: modifiedLivraisons[id] = content;
  }
  else {
	modifiedTransferts.containsKey(id) ? modifiedTransferts[id]!.addAll(content)
	: modifiedTransferts[id] = content;
  }
}

// Interface to the true modifier for easy and comprehensible arguments
void saveChange(String movement, {required int id,
				required String columnName, required String newValue}){
  saveModified(movement, id.toString(), {columnName: newValue});
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

// Global controllers for Livraison and Transfert
Map<int, TextEditingController> dateControllers = {};
Map<int, TextEditingController> logisticOfficialsControllers = {};
Map<int, TextEditingController> numeroMvtControllers = {};
Map<int, TextEditingController> plaqueControllers = {};
Map<int, TextEditingController> stockDepartControllers = {};
Map<int, TextEditingController> stockRetourControllers = {};
Map<int, TextEditingController> typeTransportControllers = {};
Map<int, TextEditingController> motifControllers = {};
Map<int, TextEditingController> photoMvtControllers = {};
Map<int, TextEditingController> photoJournalControllers = {};

String formatStock(String stock){
  return stock.replaceAll('_', ' ');
}

// Transfert-specific controller
Map<String, TextEditingController> stockSuivantsControllers = {};

TextEditingController printStockSuivants(Transfert objTransf){
  String result = "";
  for (String stock in objTransf.stock_central_suivants.values){
    result += "${formatStock(stock)} - ";
  }
  stockSuivantsControllers[objTransf.id.toString()] = TextEditingController(text: result);
  return stockSuivantsControllers[objTransf.id.toString()]!;
}

void saveStockSuivants(String id, String newValue){
  List<String> stocks = newValue.split(' - ');
  Map<String, String> newStockSuivants = {};
  int count = 0;
  for (String stock in stocks){
	if (stock != ""){
	  newStockSuivants[count.toString()] = stock.replaceAll(" ", "_");
	}
	count++;
  }
  modifiedTransferts.containsKey(id) ?
  modifiedTransferts[id]!["stock_central_suivants"] = jsonEncode(newStockSuivants)
  : modifiedTransferts[id] = {"stock_central_suivants": jsonEncode(newStockSuivants)};
}

List<DataRow> _createTransfertRows() {
  List<Transfert> data = List.from(collectedTransfert);
  return data.map((e) {
    dateControllers[e.id] = TextEditingController(text: e.date);
    plaqueControllers[e.id] = TextEditingController(text: e.plaque);
    logisticOfficialsControllers[e.id] = TextEditingController(text: e.logistic_official);
    numeroMvtControllers[e.id] = TextEditingController(text: e.numero_mouvement.toString());
    stockDepartControllers[e.id] = TextEditingController(text: formatStock(e.stock_central_depart));
    stockRetourControllers[e.id] = TextEditingController(text: formatStock(e.stock_central_retour));
    typeTransportControllers[e.id] = TextEditingController(text: e.type_transport);
    motifControllers[e.id] = TextEditingController(text: e.motif!);
    photoMvtControllers[e.id] = TextEditingController(text: e.photo_mvt);
    photoJournalControllers[e.id] = TextEditingController(text: e.photo_journal);
    return DataRow(cells: [
	  DataCell(TextField(controller: dateControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "date"); }), showEditIcon: true),

	  DataCell(TextField(controller: plaqueControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "plaque"); }), showEditIcon: true),

	  DataCell(TextField(controller: logisticOfficialsControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "logistic_official"); }), showEditIcon: true),

	  DataCell(TextField(controller: numeroMvtControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "numero_mouvement"); }), showEditIcon: true),

	  DataCell(TextField(controller: stockDepartControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "stock_central_depart"); }), showEditIcon: true),

      DataCell(TextField(controller: stockSuivantsControllers[e.id.toString()],
		onChanged: (value) {saveStockSuivants(e.id.toString(), value); },
		decoration: const InputDecoration(border: InputBorder.none)), showEditIcon: true),

	  DataCell(TextField(controller: stockRetourControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "stock_central_retour"); }), showEditIcon: true),

	  DataCell(TextField(controller: typeTransportControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "type_transport"); }), showEditIcon: true),

	  DataCell(TextField(controller: motifControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "motif"); }), showEditIcon: true),

	  DataCell(TextField(controller: photoMvtControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "photo_mvt"); }), showEditIcon: true),

	  DataCell(TextField(controller: photoJournalControllers[e.id],
		decoration: const InputDecoration(border: InputBorder.none),
		onChanged: (value) { saveChange("Transfert", id: e.id, newValue: value,
		columnName: "photo_journal"); }), showEditIcon: true),
    ]);
  }).toList();
}

// Livraison-specific controllers
Map<int, TextEditingController> districtControllers = {};
// Each member of boucle has its own id(String)
Map<String, TextEditingController> livraisonRetourControllers = {};
Map<String, TextEditingController> collineControllers = {};
Map<String, TextEditingController> inputControllers = {};
Map<String, TextEditingController> quantiteControllers = {};

Map<int, String> keys = {};

List<DataRow> _createLivraisonRows() {
  List<Livraison> _data = List.from(collectedLivraison);
  List<DataRow> rows = [];
  _data.map((e){
    dateControllers[e.id] = TextEditingController(text: e.date);
    plaqueControllers[e.id] = TextEditingController(text: e.plaque);
    logisticOfficialsControllers[e.id] = TextEditingController(text: e.logistic_official);
    numeroMvtControllers[e.id] = TextEditingController(text: e.numero_mouvement.toString());
    stockDepartControllers[e.id] = TextEditingController(text: formatStock(e.stock_central_depart));
    districtControllers[e.id] = TextEditingController(text: e.district);
    stockRetourControllers[e.id] = TextEditingController(text: formatStock(e.stock_central_retour));
    typeTransportControllers[e.id] = TextEditingController(text: e.type_transport);
    motifControllers[e.id] = TextEditingController(text: e.motif!);
    photoMvtControllers[e.id] = TextEditingController(text: e.photo_mvt);
    photoJournalControllers[e.id] = TextEditingController(text: e.photo_journal);
    for (String l in e.boucle.keys) {
	  String key = "${e.id}-$l";
	  keys[e.id] = key; // unique movement-boucle key for special controllers
	  livraisonRetourControllers[key] = TextEditingController(text: e.boucle[l]!["livraison_retour"]);
	  collineControllers[key] = TextEditingController(text: e.boucle[l]!["colline"]);
	  inputControllers[key] = TextEditingController(text: e.boucle[l]!["input"]);
	  quantiteControllers[key] = TextEditingController(text: e.boucle[l]!["quantite"]);
      DataRow row = DataRow(cells: [
        DataCell(TextField(controller: dateControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "date"); }), showEditIcon: true),

        DataCell(TextField(controller: plaqueControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "plaque"); }), showEditIcon: true),

        DataCell(TextField(controller: logisticOfficialsControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "logistic_official"); }), showEditIcon: true),

        DataCell(TextField(controller: numeroMvtControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "numero_mouvement"); }), showEditIcon: true),
        DataCell(TextField(controller: stockDepartControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "stock_central_depart"); }), showEditIcon: true),

        DataCell(TextField(controller: livraisonRetourControllers[keys[e.id]],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) {
			saveBoucle(e.id.toString(), l, "livraison_retour", value);
		  }), showEditIcon: true),

        DataCell(TextField(controller: districtControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "district"); }), showEditIcon: true),

        DataCell(TextField(controller: collineControllers[keys[e.id]],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) {
			saveBoucle(e.id.toString(), l, "colline", value);
		  }), showEditIcon: true),

        DataCell(TextField(controller: inputControllers[keys[e.id]],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) {
			saveBoucle(e.id.toString(), l, "input", value);
		  }), showEditIcon: true),

        DataCell(TextField(controller: quantiteControllers[keys[e.id]],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) {
			saveBoucle(e.id.toString(), l, "quantite", value);
		  }), showEditIcon: true),

        DataCell(TextField(controller: stockRetourControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "stock_central_retour"); }), showEditIcon: true),

        DataCell(TextField(controller: typeTransportControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "type_transport"); }), showEditIcon: true),

        DataCell(TextField(controller: motifControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "motif"); }), showEditIcon: true),

        DataCell(TextField(controller: photoMvtControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "photo_mvt"); }), showEditIcon: true),

        DataCell(TextField(controller: photoJournalControllers[e.id],
		  decoration: const InputDecoration(border: InputBorder.none),
		  onChanged: (value) { saveChange("Livraison", id: e.id, newValue: value,
		  columnName: "photo_journal"); }), showEditIcon: true),
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
        label: Text("District",
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
  final ScrollController horizontalController = ScrollController();
  return SafeArea(
      child: Scrollbar(
	  controller: horizontalController,
	  thumbVisibility: true,
	  child: SingleChildScrollView(
		controller: horizontalController,
		scrollDirection: Axis.horizontal,
		child: SingleChildScrollView(
		scrollDirection: Axis.vertical,
		child: DataTable(
			columns: _createTransfertColumns(), rows: _createTransfertRows())),
  )));
}

Widget livraisonTable() {
  final ScrollController horizontalController = ScrollController();
  return SafeArea(
	  child: Scrollbar(
		controller: horizontalController,
		thumbVisibility: true,
        child: SingleChildScrollView(
		controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
              columns: _createLivraisonColumns(), rows: _createLivraisonRows())),
        ),
      );
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
  String fileNameCopy = fileName.replaceAll(":", "-");
  fileNameCopy = fileNameCopy.replaceAll(" ", "_");
  String p = "$path\\$fileNameCopy";
  return File(p);
}

Future<File> writeCounter(String fileName, List<int> bytes) async {
  final file = await _localFile(fileName);

  // Write the file
  return file.writeAsBytes(bytes);
}
