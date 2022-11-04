import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoapp/floatingSheet/floating_sheet.dart';
import 'floatingSheet/floating_screen.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: TodoApp()));
}

class TodoApp extends StatefulWidget {
  const TodoApp({Key? key}) : super(key: key);

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  List<String> itemList = [];
  List<Map<String, dynamic>> decodedMap = [];
  List<String> floating = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final textController1 = TextEditingController();
  final textController2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    getList();
  }

  void getList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      itemList = prefs.getStringList("items") ?? [];
      floating = prefs.getStringList('all-list') ?? [];
      for (final i in itemList) {
        decodedMap.add(jsonDecode(i));
      }
    });
  }

  void _addItems(String title, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final value = {'title': title, 'description': description, 'state': false};
    setState(() {
      itemList = prefs.getStringList("items") ?? [];
      itemList.add(jsonEncode(value));
      decodedMap.clear();
      for (final i in itemList) {
        decodedMap.add(jsonDecode(i));
      }
    });
    await prefs.setStringList('all-list', floating);
    await prefs.setStringList('items', itemList);

    textController1.clear();
    textController2.clear();
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a task'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: textController1,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'Enter Title '),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter Title";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: textController2,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    decoration:
                        const InputDecoration(hintText: 'Enter Description '),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter Description";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _addItems(textController1.text, textController2.text);
                  floating.add(jsonEncode({
                    'title': textController1.text,
                    'description': textController2.text
                  }));
                  Navigator.of(context).pop();
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                textController1.clear();
                textController2.clear();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        floatingActionButton: SafeArea(
          child: FloatingActionButton(
            elevation: 16.0,
            tooltip: 'Add',
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 5.0),
            ),
            backgroundColor: Colors.blueGrey,
            onPressed: () {
              _showMyDialog();
            },
            child: const Icon(Icons.add),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => showFloatingModalBottomSheet(
                  context: context,
                  builder: (context) => ModalFit(floating),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.menu),
                    Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text(
                        'Todo',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: MySearchDelegate(itemList),
                  );
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        body: ListView.builder(
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            itemCount: decodedMap.length,
            itemBuilder: (BuildContext context, int index) {
              return Dismissible(
                // Each Dismissible must contain a Key.  Keys allow Flutter to
                // uniquely identify widgets.
                key: Key(decodedMap[index]['title']),
                confirmDismiss: (direction) {
                  return showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                            ),
                            title: const Text("Confirmation"),
                            content:
                                const Text("Are you sure you want to delete?"),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text("Yes"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text("NO"),
                              ),
                            ],
                          ));
                },
                // Provide a function that tells the app
                // what to do after an item has been swiped away.
                onDismissed: (direction) async {
                  // Remove the item from the data source.
                  final prefs = await SharedPreferences.getInstance();
                  itemList.removeAt(index);
                  decodedMap.removeAt(index);
                  await prefs.remove("items");
                  await prefs.setStringList("items", itemList);
                  setState(() {});
                },
                // Show a red background as the item is swiped away.

                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.only(left: 25),
                  alignment: Alignment.centerLeft,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.only(right: 25),
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                child: Card(
                  elevation: 2.0,
                  child: CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    activeColor: Colors.grey,
                    contentPadding: const EdgeInsets.all(2.0),
                    title: Padding(
                      padding: decodedMap[index]['state']
                          ? const EdgeInsets.only(left: 40.0)
                          : const EdgeInsets.only(left: 25.0),
                      child: Text(
                        jsonDecode(itemList[index])['title'],
                        style: decodedMap[index]['state']
                            ? const TextStyle(
                                fontSize: 24,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic)
                            : const TextStyle(fontSize: 28),
                      ),
                    ),
                    subtitle: Padding(
                      padding: decodedMap[index]['state']
                          ? const EdgeInsets.only(left: 40.0)
                          : const EdgeInsets.only(left: 25.0),
                      child: Text(
                        jsonDecode(itemList[index])['description'],
                        style: decodedMap[index]['state']
                            ? const TextStyle(
                                fontSize: 15,
                                decoration: TextDecoration.lineThrough,
                                fontStyle: FontStyle.italic)
                            : const TextStyle(fontSize: 20),
                      ),
                    ),
                    value: decodedMap[index]['state'],
                    onChanged: (bool? value) async{
                      decodedMap[index]['state'] = value!;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove("items");
                      await prefs.setStringList("items", [for(int i = 0; i < decodedMap.length; i++) jsonEncode(decodedMap[i])]);

                      setState(
                        () {
                        },
                      );
                    },
                  ),
                ),
              );
            }),
      ),
    );
  }
}

class MySearchDelegate extends SearchDelegate {
  List<String> suggestion;

  MySearchDelegate(this.suggestion);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          onPressed: () {
            query = "";
          },
          icon: const Icon(Icons.cancel),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: const Icon(Icons.arrow_back_ios_outlined),
      );

  @override
  Widget buildResults(BuildContext context) => Center(
        child: Text(query),
      );

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> suggestions = suggestion.where((searchResult) {
      final result = jsonDecode(searchResult)["title"].toLowerCase();
      final result2 = jsonDecode(searchResult)["description"].toLowerCase();
      final input = query.toLowerCase();
      if (result.contains(input)) {
        return result.contains(input);
      } else {
        return result2.contains(input);
      }
    }).toList();
    return ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final sugg = jsonDecode(suggestions[index])['title'];
          final sugg2 = jsonDecode(suggestions[index])['description'];
          return ListTile(
            title: query.isEmpty ? null : Text(sugg),
            subtitle: query.isEmpty ? null : Text(sugg2),
            onTap: () {
              query = sugg;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Result(suggestions, index)));
            },
          );
        });
  }
}

//ignore: must_be_immutable
class Result extends StatefulWidget {
  List<String> value;
  int index;
  Result(this.value, this.index, {Key? key}) : super(key: key);
  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Title : ${jsonDecode(widget.value[widget.index])["title"]}"),
        elevation: 2.0,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.description,
                color: Colors.teal,
              ),
              title: const Text(
                "Description :",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                jsonDecode(widget.value[widget.index])["description"],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
