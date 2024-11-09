import 'package:flutter/material.dart';
import 'package:collecteur/excel_fields.dart';
import 'package:collecteur/rest.dart';

Map<int, Iterable<String?>> cache = {};
Map<String?, Iterable<String?>> cache2 = {};

DateTime? dateSelected;
bool collineDisponible = false;
Color background = Colors.white;

// Function to list all the contents of the specified column in the sheet
void list(int column, {String? district}) async{
  Worksheet workSheet = await Worksheet.fromAsset("assets/worksheet.xlsx");
  if (district == null) {
    cache[column] = workSheet.readColumn("Feuille 1", column);
  }
  else{
    if (cache2.containsKey(district) == true){
      return;
    }
    cache2[district] = workSheet.readColline("Feuille 1", district);
  }
}

void initialize({String? district}){
  if (district != null){
    list(DISTRICT+5, district: district);
    return;
  }
  list(STOCK_CENTRAL);
  list(TYPE_TRANSPORT);
  list(PROGRAM);
  list(INPUT);
  list(DISTRICT);
  list(LIVRAISON_RETOUR);
}

// Custom DatePicker widget
class DatePicker extends StatefulWidget {
  const DatePicker({super.key});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _date;
  Future _selectDate(BuildContext context) async => showDatePicker(context: context,
      firstDate: DateTime(2005), lastDate: DateTime(2090), initialDate: DateTime.now()
  ).then((DateTime? selected) {
    if (selected != null && selected != _date) {
      setState(() {
        _date = selected;
        dateSelected = _date;
      });
    }
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(onPressed: () => _selectDate(context),
            style: ElevatedButton.styleFrom(backgroundColor: background),
            child: Text(_date == null ? "Date..." : "${_date?.day} / ${_date?.month} / ${_date?.year}",
                style: TextStyle(color: background == Colors.white ? Colors.black : Colors.white),
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
  const Stock({super.key, required this.hintText, required this.column,
    required this.background, this.district, required this.onSelect});

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  String _hintCopy = "Default";

  @override
  void initState(){
    _hintCopy = widget.hintText;
    super.initState();
    if (widget.district != null){
      list(DISTRICT+5, district: widget.district);
    }
    else {
      list(widget.column);
    }
    }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: DropdownButton<String?>(items: (widget.district != null ? cache2[widget.district] : cache[widget.column])
          ?.map((choice){
        return DropdownMenuItem(value: choice, child: Text(choice.toString()));
      }).toList(), onChanged: (value){
        setState(() {
          _hintCopy = value!;
          widget.onSelect(value);
        });
      }, hint: Text(_hintCopy, style: TextStyle(color: widget.background == Colors.white ? Colors.black
          : Colors.white)),
    style: TextStyle(color: widget.background == Colors.white ?  Colors.black
        : Colors.white)
    ));
  }
}