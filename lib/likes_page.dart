import 'dart:convert';
import 'package:flutter/material.dart';
import 'my_bluetooth_service.dart';

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

    // Bluetooth 데이터 수신 시 utf8로 인코딩하여 메시지를 처리
    MyBluetoothService.instance.alertStream?.listen((data) {
      String receivedMessage = utf8.decode(data).trim();
      print('Received message: $receivedMessage');
      if (receivedMessage.contains('응급상황')) {
        setState(() {
          alertMessage = '응급상황입니다!';
        });
      }
    });

    // 연결 끊김 이벤트 처리
    MyBluetoothService.instance.disconnectionStream.listen((_) {
      setState(() {
        alertMessage = '연결이 끊어졌습니다';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Likes Page')),
      body: Center(
        child: Text(
          alertMessage,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
