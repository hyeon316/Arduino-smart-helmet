import 'package:flutter/material.dart';
import 'bluetooth_service.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  _LikesPageState createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  String alertMessage = '안전운전하세요';

  @override
  void initState() {
    super.initState();
    MyBluetoothService.instance.alertStream?.listen((value) {
      String receivedMessage = String.fromCharCodes(value);
      if (receivedMessage.contains('응급상황')) {
        setState(() {
          alertMessage = '응급상황입니다!';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        alertMessage,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
      ),
    );
  }
}
