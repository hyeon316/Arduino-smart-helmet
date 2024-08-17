import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart'; // 추가된 부분
import 'my_bluetooth_service.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  _LikesPageState createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  static const platform = MethodChannel('sms_plugin');
  String alertMessage = '안전운전하세요';
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    MyBluetoothService.instance.alertStream?.listen((data) {
      String receivedMessage = utf8.decode(data).trim();
      print('Received message: $receivedMessage');
      if (receivedMessage.contains('응급상황')) {
        setState(() {
          alertMessage = '응급상황입니다!';
        });
        _startTimer();
      }
    });

    MyBluetoothService.instance.disconnectionStream.listen((_) {
      setState(() {
        alertMessage = '연결이 끊어졌습니다';
        _resetTimer();
      });
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 5;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _sendHelpMessage();
          _timer?.cancel();
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 5;
      alertMessage = '안전운전하세요';
    });
  }

  Future<void> _sendHelpMessage() async {
    // SMS 권한 상태 확인
    var status = await Permission.sms.status;
    if (status.isGranted) {
      try {
        final String result = await platform.invokeMethod('sendSMS', {"number": "0000", "message": "help"});
        print(result);
      } on PlatformException catch (e) {
        print("Failed to send SMS: '${e.message}'.");
      }
    } else {
      // 권한이 부여되지 않았으면 요청
      if (await Permission.sms.request().isGranted) {
        try {
          final String result = await platform.invokeMethod('sendSMS', {"number": "0000", "message": "help"});
          print(result);
        } on PlatformException catch (e) {
          print("Failed to send SMS: '${e.message}'.");
        }
      } else {
        print("SMS permission not granted");
      }
    }
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Likes Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              alertMessage,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (alertMessage == '응급상황입니다!') ...[
              const SizedBox(height: 20),
              Text(
                '$_secondsRemaining 초 후 자동 신고',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetTimer,
                child: const Text('정지'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
