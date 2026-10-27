import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:kavaid/services/search_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('fihrist dosyaya yazılıp geri okununca bellekteki hâliyle birebir aynı', () async {
    final words = await EmbeddedWords.load();
    final dir = Directory.systemTemp.createTempSync('kavaid_store');
    addTearDown(() => dir.deleteSync(recursive: true));

    final built = SearchStore.build(words, dir: dir.path, version: 'test');
    final opened = SearchStore.open(dir.path, 'test');

    expect(opened, isNotNull);
    expect(opened!.length, words.length);
    expect(opened.nHarekeli, built.nHarekeli);
    expect(opened.nKelime, built.nKelime);
    expect(opened.nKoku, built.nKoku);
    expect(opened.popularity, built.popularity);
    expect(opened.kelime, built.kelime);
    expect(opened.harekeli, built.harekeli);
    expect(opened.koku, built.koku);
    // Satır sonu temizlenen nadir anlamlar dışında aynı
    var differentMeanings = 0;
    for (var i = 0; i < words.length; i++) {
      if (opened.meanings[i] != built.meanings[i]) differentMeanings++;
    }
    expect(differentMeanings, lessThan(5));
    for (final i in [0, 1, 777, words.length ~/ 2, words.length - 1]) {
      expect(opened.record(i), words[i]);
    }
    built.close();
    opened.close();
  });

  test('başka sürümün dosyaları silinir', () async {
    final words = (await EmbeddedWords.load()).take(50).toList();
    final dir = Directory.systemTemp.createTempSync('kavaid_store');
    addTearDown(() => dir.deleteSync(recursive: true));

    SearchStore.build(words, dir: dir.path, version: 'v1').close();
    SearchStore.build(words, dir: dir.path, version: 'v2').close();

    expect(SearchStore.exists(dir.path, 'v1'), isFalse);
    expect(SearchStore.exists(dir.path, 'v2'), isTrue);
  });
}
