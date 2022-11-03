import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModalFit extends StatefulWidget {
  List<String> receivedList;
  ModalFit(this.receivedList, {Key? key}) : super(key: key);
  @override
  State<ModalFit> createState() => _ModalFitState();
}

class _ModalFitState extends State<ModalFit> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            IconButton(onPressed:() async {
              widget.receivedList.clear();
              final prefs = await SharedPreferences.getInstance();
              prefs.remove('all-list');
              setState(() {
              });
            }, icon: const Icon(Icons.delete),color: Colors.red,),
            ListView.builder(
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.receivedList.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 2.0,
                  child: ListTile(
                    title: Text(jsonDecode(widget.receivedList[index])['title']),
                    subtitle:
                        Text(jsonDecode(widget.receivedList[index])['description']),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
