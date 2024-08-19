// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // 추가된 부분
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
  String _currentLocation = ''; // 현재 위치를 저장하는 변수

  @override
  void initState() {
    super.initState();

    _determinePosition();

    MyBluetoothService.instance.alertStream.listen((data) {
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

  // 현재 위치 가져오기
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 사용 가능 여부 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('위치 서비스를 사용할 수 없습니다.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('위치 권한이 거부되었습니다.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('위치 권한이 영구적으로 거부되었습니다.');
      return;
    }

    // 위치 가져오기
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = '${position.latitude}, ${position.longitude}';
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 5;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    var status = await Permission.sms.status;
    if (status.isGranted) {
      try {
        String message = "응급상황 발생! 위치: $_currentLocation";
        final String result = await platform.invokeMethod('sendSMS', {"number": "0000", "message": message});
        print(result);
      } on PlatformException catch (e) {
        print("Failed to send SMS: '${e.message}'.");
      }
    } else {
      if (await Permission.sms.request().isGranted) {
        try {
          String message = "응급상황 발생! 위치: $_currentLocation";
          final String result = await platform.invokeMethod('sendSMS', {"number": "0000", "message": message});
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
