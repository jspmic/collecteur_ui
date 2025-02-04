import 'package:flutter/material.dart';
import 'package:Collecteur/rest.dart';

class addUser extends StatefulWidget {
  const addUser({super.key});

  @override
  State<addUser> createState() => _addUserState();
}

class _addUserState extends State<addUser> {
  @override
  Widget build(BuildContext context) {
    return const Interface();
  }
}

class Interface extends StatefulWidget {
  const Interface({super.key});

  @override
  State<Interface> createState() => _InterfaceState();
}

class _InterfaceState extends State<Interface> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Color? background = Colors.white;
  var username = TextEditingController();
  var pssw = TextEditingController();
  bool passwordVisible = false;
  bool isLoading = false;
  String _uname = "";
  String _pssw = "";
  Color? state = Colors.black;

  String? _validateField(String? value){
    setState(() {
      state = Colors.red;
    });
    return value == null || value.isEmpty ? "Champ obligatoire" : null;
  }

  void addGivenUser() async{
    if (_formKey.currentState!.validate()){
      _formKey.currentState?.save();
    }
    else{
      return;
    }
  setState(() {
	isLoading = true;
	state = Colors.blue;
  });
  bool checkState = await addUserMethod(username.text, pssw.text);
  setState(() {
	isLoading = false;
	state = checkState ? Colors.green : Colors.red;
  });
  }

  @override
  Widget build(BuildContext context){
  return SafeArea(child: Scaffold(
  appBar: AppBar(title: ClipRRect(
		  borderRadius: BorderRadius.circular(20),
		  child: Image.asset("assets/icon/drawer2.png",
			  fit: BoxFit.cover, width: 40, height: 40),
		), centerTitle: true,
  ),
  body: Container(
	padding: EdgeInsets.all(MediaQuery.of(context).size.height/18),
	  child: SingleChildScrollView(
		  child: Column(children: [
		SizedBox(
		  height: MediaQuery.of(context).size.height/7,
		),
		const SizedBox(
		  height: 25.0,
		),
			Icon(Icons.circle_outlined, color: state),
			const SizedBox(height: 8),
		Form(key: _formKey, child: Padding(padding: const EdgeInsets.all(16.0), child:
		  Column(
			children: [
			  TextFormField(
				decoration: InputDecoration(
				  labelText: "Nom d'utilisateur",
					labelStyle: TextStyle(color: background == Colors.white ? Colors.black : Colors.white, fontSize: 16),
				),
				controller: username,
				style: TextStyle(color: background == Colors.white ? Colors.black : Colors.white),
				validator: (value) => _validateField(value),
				onSaved: (value) => _uname = value!,
			  ),
			  const SizedBox(height: 15),
			  TextFormField(
				decoration: InputDecoration(
					labelText: "Mot de passe",
					suffixIcon: IconButton(onPressed: () {
					setState(() {
					  passwordVisible = !passwordVisible;
					});
					}, icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off)),
				  labelStyle: TextStyle(color: background == Colors.white ? Colors.black : Colors.white, fontSize: 16)
				),
				obscureText: !passwordVisible,
				controller: pssw,
				style: TextStyle(color: background == Colors.white ? Colors.black : Colors.white),
				validator: (value) => _validateField(value),
				onSaved: (value) => _pssw = value!,
			  )
			],
		  ))),
			const SizedBox(height: 12.0),
			isLoading ? const CircularProgressIndicator()
				: ElevatedButton(onPressed: addGivenUser,
			  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
			  child: const Icon(Icons.add))
	  ])),
  )));
  }
}
