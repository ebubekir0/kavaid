import 'dart:convert';
import 'dart:io';

void main() async {
  final List<String> bookIds = [
    'alice_harikalar_diyarinda',
    'don_kisot',
    'oliver_twist',
    'yasli_adam_ve_deniz',
    'monte_kristo_kontu',
    'seksen_gunde_devrialem',
    'hz_musa_ve_hizirin_yolculugu',
    'kucuk_prens',
    'robinson_crusoe',
    'sherlock_holmesun_zekasi'
  ];

  for (String id in bookIds) {
    print('Estimating timestamps for: $id');
    final File jsonFile = File('assets/books/$id/full_book.json');
    if (!await jsonFile.exists()) continue;

    final Map<String, dynamic> data = jsonDecode(await jsonFile.readAsString());
    List<dynamic> kelimeler = data['kelimeler'];

    double currentTime = 0.0;
    const double wordDuration = 0.6; // Ortalama okuma hızı tahmini

    for (var kelime in kelimeler) {
      if (kelime['type'] == 'word') {
        kelime['start'] = double.parse(currentTime.toStringAsFixed(2));
        currentTime += wordDuration;
        kelime['end'] = double.parse(currentTime.toStringAsFixed(2));
      }
    }

    await jsonFile.writeAsString(jsonEncode(data));
    print('Updated timestamps for $id (Total time: ${currentTime.toStringAsFixed(1)}s)');
  }
}
