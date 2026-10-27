import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'search_ranking.dart';

/// Arama izolesinin bellekte tuttuğu küçük fihrist ve telefona yazılmış kayıt dosyası.
///
/// Eskiden arama izolesi her açılışta 37 MB'lık sözlüğün tamamını belleğe açıyordu
/// (Galaxy A16'da uygulama 447 MB bellek kullanıyordu, arama 4 sn'de hazır oluyordu).
/// Artık sözlük sürümü değişince bir kez iki dosya yazılır:
///   `dict_SÜRÜM.jsonl`   her satırda bir kayıt (JSON)
///   `search_SÜRÜM.idx`   her kayıt için aranan kısa hâller + kaydın dosyadaki yeri
/// Sonraki açılışlarda yalnız fihrist okunur; sonuçların ayrıntısı dosyadan çekilir.
/// Veritabanındaki `words` tablosu harekesiz yazılışa göre tekil olduğu için
/// (دِين / دَيْن aynı satıra düşer) kayıtlar oradan değil bu dosyadan okunur.
class SearchStore {
  SearchStore._({
    required this.kelime,
    required this.harekeli,
    required this.koku,
    required this.mainMeaning,
    required this.nKelime,
    required this.nHarekeli,
    required this.nKoku,
    required this.meanings,
    required this.popularity,
    required this.imperative,
    Int32List? offsets,
    Int32List? lengths,
    RandomAccessFile? records,
    List<Map<String, dynamic>>? maps,
  })  : _offsets = offsets,
        _lengths = lengths,
        _records = records,
        _maps = maps;

  // Fihrist biçimi değişince (anlam normalleştirmesi gibi) artar; eski fihrist
  // dosyası yok sayılıp yeniden kurulur.
  static const _magic = 'kavaid-search-3';
  static const _idxPrefix = 'search3_';
  static const _sep = '\u0001';

  // rankEntry'nin ham hâlleri
  final List<String> kelime;
  final List<String> harekeli;
  final List<String> koku;
  final List<String> mainMeaning;
  // Önceden normalize edilmiş hâller (search_ranking.dart kuralları)
  final List<String> nKelime;
  final List<String> nHarekeli;
  final List<String> nKoku;
  final List<String> meanings;
  // Her kaydın kökünden sözlükte kaç kayıt türediği: yaygınlık ölçüsü
  final List<int> popularity;
  // Emir kipi mi (anlamla aramada temel biçimden sonra gelir)
  final List<bool> imperative;

  final Int32List? _offsets;
  final Int32List? _lengths;
  final RandomAccessFile? _records;
  // Dosya yazılamadığında (yedek yol) kayıtlar bellekte kalır
  final List<Map<String, dynamic>>? _maps;

  int get length => kelime.length;

  /// Kayıt dosyasını kapatır (sözlük dili değişince eski fihrist bırakılırken).
  void close() {
    try {
      _records?.closeSync();
    } catch (_) {}
  }

  /// [i]. kaydın tamamı (sonuç kartı için).
  Map<String, dynamic> record(int i) {
    final maps = _maps;
    if (maps != null) return Map<String, dynamic>.from(maps[i]);
    final file = _records!..setPositionSync(_offsets![i]);
    final bytes = file.readSync(_lengths![i]);
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
  }

  static String _idxPath(String dir, String version) => '$dir/$_idxPrefix$version.idx';
  static String _dictPath(String dir, String version) => '$dir/dict_$version.jsonl';

  static bool exists(String dir, String version) =>
      File(_idxPath(dir, version)).existsSync() && File(_dictPath(dir, version)).existsSync();

  /// Bu sürümün dosyaları varsa fihristi okur; yoksa ya da bozuksa null.
  static SearchStore? open(String dir, String version) {
    if (!exists(dir, version)) return null;
    try {
      final lines = File(_idxPath(dir, version)).readAsStringSync().split('\n');
      final head = lines.first.split('\t');
      if (head.first != _magic) return null;
      final n = int.parse(head[1]);
      final k = List<String>.filled(n, ''), hk = List<String>.filled(n, ''), root = List<String>.filled(n, '');
      final main = List<String>.filled(n, ''), nk = List<String>.filled(n, ''), nhk = List<String>.filled(n, '');
      final nroot = List<String>.filled(n, ''), mean = List<String>.filled(n, '');
      final pop = List<int>.filled(n, 0);
      final imp = List<bool>.filled(n, false);
      final offsets = Int32List(n), lengths = Int32List(n);
      for (var i = 0; i < n; i++) {
        final f = lines[i + 1].split(_sep);
        k[i] = f[0];
        hk[i] = f[1];
        root[i] = f[2];
        main[i] = f[3];
        nk[i] = f[4];
        nhk[i] = f[5];
        nroot[i] = f[6];
        mean[i] = f[7];
        pop[i] = int.parse(f[8]);
        offsets[i] = int.parse(f[9]);
        lengths[i] = int.parse(f[10]);
        imp[i] = f[11] == '1';
      }
      return SearchStore._(
        kelime: k,
        harekeli: hk,
        koku: root,
        mainMeaning: main,
        nKelime: nk,
        nHarekeli: nhk,
        nKoku: nroot,
        meanings: mean,
        popularity: pop,
        imperative: imp,
        offsets: offsets,
        lengths: lengths,
        records: File(_dictPath(dir, version)).openSync(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Kayıtlardan fihristi kurar. [dir] verilirse dosyaları yazar ve kayıtları
  /// bellekten bırakır; yazılamazsa kayıtlar bellekte kalır (eski davranış).
  static SearchStore build(List<Map<String, dynamic>> words, {String? dir, String? version}) {
    final n = words.length;
    final f = _Fields()..add(words, 0, n);
    final k = f.k, hk = f.hk, root = f.root, main = f.main;
    final nk = f.nk, nhk = f.nhk, nroot = f.nroot, mean = f.mean, imp = f.imp;
    final pop = rootPopularity(nroot);

    if (dir != null && version != null) {
      try {
        final offsets = Int32List(n), lengths = Int32List(n);
        _writeRecords(words, _dictPath(dir, version), offsets, lengths);
        final idx = StringBuffer('$_magic\t$n');
        String clean(String s) => s.replaceAll('\n', ' ').replaceAll(_sep, ' ');
        for (var i = 0; i < n; i++) {
          idx
            ..write('\n')
            ..writeAll([
              clean(k[i]), clean(hk[i]), clean(root[i]), clean(main[i]),
              clean(nk[i]), clean(nhk[i]), clean(nroot[i]), clean(mean[i]),
              pop[i], offsets[i], lengths[i], imp[i] ? 1 : 0,
            ], _sep);
        }
        final tmp = File('${_idxPath(dir, version)}.tmp')..writeAsStringSync(idx.toString(), flush: true);
        tmp.renameSync(_idxPath(dir, version));
        _deleteOtherVersions(dir, version);
        return SearchStore._(
          kelime: k,
          harekeli: hk,
          koku: root,
          mainMeaning: main,
          nKelime: nk,
          nHarekeli: nhk,
          nKoku: nroot,
          meanings: mean,
          popularity: pop,
          imperative: imp,
          offsets: offsets,
          lengths: lengths,
          records: File(_dictPath(dir, version)).openSync(),
        );
      } catch (_) {
        // Yazılamadı: kayıtlar bellekte kalsın
      }
    }
    return SearchStore._(
      kelime: k,
      harekeli: hk,
      koku: root,
      mainMeaning: main,
      nKelime: nk,
      nHarekeli: nhk,
      nKoku: nroot,
      meanings: mean,
      popularity: pop,
      imperative: imp,
      maps: words,
    );
  }

  /// Ana izolede yedek yol: izole başlatılamazsa fihrist bellekte, parça parça
  /// kurulur (arayüz donmasın diye her [chunkSize] kayıtta bir olay döngüsüne döner).
  static Future<SearchStore> buildInMemory(List<Map<String, dynamic>> words, {int chunkSize = 700}) async {
    final f = _Fields();
    for (var start = 0; start < words.length; start += chunkSize) {
      final end = start + chunkSize < words.length ? start + chunkSize : words.length;
      f.add(words, start, end);
      await Future<void>.delayed(Duration.zero);
    }
    return SearchStore._(
      kelime: f.k,
      harekeli: f.hk,
      koku: f.root,
      mainMeaning: f.main,
      nKelime: f.nk,
      nHarekeli: f.nhk,
      nKoku: f.nroot,
      meanings: f.mean,
      popularity: rootPopularity(f.nroot),
      imperative: f.imp,
      maps: words,
    );
  }

  static void _writeRecords(List<Map<String, dynamic>> words, String path, Int32List offsets, Int32List lengths) {
    final tmp = File('$path.tmp');
    final out = tmp.openSync(mode: FileMode.write);
    try {
      final buffer = BytesBuilder(copy: false);
      var pos = 0;
      for (var i = 0; i < words.length; i++) {
        final bytes = utf8.encode(jsonEncode(words[i]));
        offsets[i] = pos;
        lengths[i] = bytes.length;
        buffer
          ..add(bytes)
          ..addByte(0x0A);
        pos += bytes.length + 1;
        if (buffer.length > 1 << 20) out.writeFromSync(buffer.takeBytes());
      }
      out.writeFromSync(buffer.takeBytes());
      out.flushSync();
    } finally {
      out.closeSync();
    }
    tmp.renameSync(path);
  }

  static void _deleteOtherVersions(String dir, String version) {
    final keep = {'$_idxPrefix$version.idx', 'dict_$version.jsonl'};
    for (final f in Directory(dir).listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      final ours = (name.startsWith('search') && name.endsWith('.idx')) ||
          (name.startsWith('dict_') && name.endsWith('.jsonl')) ||
          name.endsWith('.idx.tmp') ||
          name.endsWith('.jsonl.tmp');
      if (ours && !keep.contains(name)) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// Anlamın harf-i cer bölümü (|| sonrası) hariç ana kısmı.
  static String mainMeaningOf(String? anlam) {
    if (anlam == null || anlam.isEmpty) return '';
    final pipe = anlam.indexOf('||');
    return pipe >= 0 ? anlam.substring(0, pipe) : anlam;
  }

  /// [roots] listesindeki her kökün kaç kez geçtiği, kayıt sırasıyla.
  static List<int> rootPopularity(List<String> roots) {
    final counts = <String, int>{};
    for (final r in roots) {
      if (r.isEmpty) continue;
      final key = r.replaceAll(' ', '');
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return [for (final r in roots) r.isEmpty ? 0 : counts[r.replaceAll(' ', '')]!];
  }
}

/// Fihrist alanlarını kayıtlardan sırayla doldurur.
class _Fields {
  final k = <String>[], hk = <String>[], root = <String>[], main = <String>[];
  final nk = <String>[], nhk = <String>[], nroot = <String>[], mean = <String>[];
  final imp = <bool>[];

  void add(List<Map<String, dynamic>> words, int start, int end) {
    for (var i = start; i < end; i++) {
      final map = words[i];
      final rawK = map['kelime'] as String? ?? '';
      final rawHK = map['harekeliKelime'] as String? ?? '';
      final rawRoot = map['koku'] as String? ?? '';
      final rawMain = SearchStore.mainMeaningOf(map['anlam'] as String?);
      k.add(rawK);
      hk.add(rawHK);
      root.add(rawRoot);
      main.add(rawMain);
      nk.add(rawK.isEmpty ? '' : normalizeArabic(rawK));
      nhk.add(rawHK.isEmpty ? '' : normalizeArabic(rawHK));
      nroot.add(rawRoot.isEmpty ? '' : normalizeArabic(rawRoot));
      mean.add(normalizeMeaning(rawMain));
      final type = (map['dilbilgiselOzellikler'] as Map?)?['tur'];
      imp.add(type is String && type.contains('Emir'));
    }
  }
}
