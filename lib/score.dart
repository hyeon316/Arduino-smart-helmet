import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  final List<Map<String, String>> universities = [
    {'name': '경희대학교', 'logo': 'assets/kyunghee.png'},
    {'name': '한양대학교', 'logo': 'assets/hanyang.png'},
    {'name': '연세대학교', 'logo': 'assets/yonsei.png'},
    {'name': '중앙대학교', 'logo': 'assets/chungang.png'},
    {'name': '동국대학교', 'logo': 'assets/dongguk.png'},
    {'name': '고려대학교', 'logo': 'assets/korea.png'},
    {'name': '서울대학교', 'logo': 'assets/seoul.png'},
    {'name': '건국대학교', 'logo': 'assets/kunkuk.png'},
    {'name': '성균관대학교', 'logo': 'assets/skku.png'},
    {'name': '홍익대학교', 'logo': 'assets/hongik.png'},
  ];

  final List<int> _predefinedScores = [50000, 48000, 46000, 44000, 42000, 40000, 38000, 36000, 34000, 32000];
  List<int> _scores = [];
  bool _isLoading = true; // 점수 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  // SharedPreferences에서 점수를 로드
  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scores = List<int>.generate(universities.length, (index) {
        return prefs.getInt('score_$index') ?? _predefinedScores[index];
      });
      _isLoading = false; // 점수 로드 완료
    });
  }

  // SharedPreferences에 점수를 저장
  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _scores.length; i++) {
      await prefs.setInt('score_$i', _scores[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('서울 대학교 순위')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때 표시
          : ListView.builder(
              itemCount: universities.length,
              itemBuilder: (context, index) {
                final university = universities[index];
                final score = _scores[index]; // 고정된 점수 사용

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${index + 1}위', style: const TextStyle(fontSize: 18)),
                      Image.asset(
                        university['logo']!,
                        width: 50,
                        height: 50,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(university['name']!, style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis),
                            Text('점수: $score', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _saveScores(); // 앱이 종료될 때 점수 저장
    super.dispose();
  }
}
