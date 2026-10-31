import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const QuranApp());

const Map<String, int> kSurahNumbers = {
  'الفاتحة': 1,
  'الإخلاص': 112,
};

const Map<String, List<String>> kSurahs = {
  'الفاتحة': [
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'الرَّحْمَٰنِ الرَّحِيمِ',
    'مَالِكِ يَوْمِ الدِّينِ',
    'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
    'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
    'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
  ],
  'الإخلاص': [
    'قُلْ هُوَ اللَّهُ أَحَدٌ',
    'اللَّهُ الصَّمَدُ',
    'لَمْ يَلِدْ وَلَمْ يُولَدْ',
    'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
  ],
};

const Map<String, String> kReciters = {
  'محمود خليل الحصري (المعلم)': 'Husary_Muallim_128kbps',
  'مشاري راشد العفاسي': 'Alafasy_128kbps',
  'محمد صديق المنشاوي (مرتل)': 'Minshawy_Murattal_128kbps',
  'عبد الباسط عبد الصمد (مرتل)': 'Abdul_Basit_Murattal_192kbps',
  'ماهر المعيقلي': 'MaherAlMuaiqly128kbps',
  'سعود الشريم': 'Saood_ash-Shuraym_128kbps',
};

String normalize(String s) {
  s = s.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '');
  s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مصحّح التلاوة',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1B6B4A), useMaterial3: true),
        home: const Directionality(textDirection: TextDirection.rtl, child: HomePage()),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _playingAudio = false;
  String _surah = kSurahs.keys.first;
  String _reciter = kReciters.keys.first;
  int _ayah = 0;
  
  final TextEditingController _inputController = TextEditingController();
  List> _checkedWords = [];

  String get _ayahText => kSurahs[_surah]![_ayah];

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingAudio = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _toggleReciterAudio() async {
    if (_playingAudio) {
      await _audioPlayer.stop();
      setState(() => _playingAudio = false);
      return;
    }
    final sNum = kSurahNumbers[_surah]!.toString().padLeft(3, '0');
    final aNum = (_ayah + 1).toString().padLeft(3, '0');
    final reciterId = kReciters[_reciter]!;
    final url = 'https://everyayah.com/data/$reciterId/$sNum$aNum.mp3';

    setState(() => _playingAudio = true);
    await _audioPlayer.play(UrlSource(url));
  }

  void _checkRecitation() {
    final expectedWords = _ayahText.split(' ');
    final spokenWords = normalize(_inputController.text).split(' ');
    
    List> result = [];
    for (int i = 0; i < expectedWords.length; i++) {
      String cleanExpected = normalize(expectedWords[i]);
      bool found = spokenWords.contains(cleanExpected);
      result.add({
        'word': expectedWords[i],
        'status': found ? 'correct' : 'wrong'
      });
    }
    setState(() => _checkedWords = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مصحّح تلاوة القرآن الكريم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _surah,
                decoration: const InputDecoration(labelText: 'السورة'),
                items: kSurahs.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) {
                  _audioPlayer.stop();
                  setState(() {
                    _surah = v!;
                    _ayah = 0;
                    _playingAudio = false;
                    _checkedWords = [];
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _ayah,
                decoration: const InputDecoration(labelText: 'الآية'),
                items: [
                  for (var i = 0; i < kSurahs[_surah]!.length; i++)
                    DropdownMenuItem(value: i, child: Text('${i + 1}'))
                ],
                onChanged: (v) {
                  _audioPlayer.stop();
                  setState(() {
                    _ayah = v!;
                    _playingAudio = false;
                    _checkedWords = [];
                  });
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _reciter,
            decoration: const InputDecoration(labelText: 'اختر القارئ المعلم'),
            items: kReciters.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
            onChanged: (v) {
              _audioPlayer.stop();
              setState(() {
                _reciter = v!;
                _playingAudio = false;
              });
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _ayahText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, height: 2.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _toggleReciterAudio,
              icon: Icon(_playingAudio ? Icons.stop_circle : Icons.volume_up),
              label: Text(_playingAudio ? 'إيقاف القارئ' : 'استمع لتلاوة القارئ'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'اكتب الكلمات التي قرأتها لفحص مطابقتها',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _checkRecitation,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
            child: const Text('فحص وتصحيح التلاوة', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
          if (_checkedWords.isNotEmpty) ...[
            const Text('نتائج التصحيح:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _checkedWords.map((item) {
                bool isCorrect = item['status'] == 'correct';
                return Chip(
                  label: Text(item['word']!, style: TextStyle(color: isCorrect ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold)),
                  backgroundColor: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
