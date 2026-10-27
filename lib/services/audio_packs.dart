import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart' show ZipDecoder;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Öğren hikâyelerinin sesleri. Uygulamanın içinde değil (indirme boyutundan 17,6 MB),
/// Firebase Storage'da kitap kitap durur: `audio/<kitap>.zip` (`content/audio_packs/`).
/// Kitap ilk açıldığında arka planda iner, telefona açılır; sonra internetsiz çalışır.
/// İnmeden önce ya da internet yokken TTSService telefonun okuma sesine geçer.
class AudioPacks {
  AudioPacks._();

  static final Map<String, Future<bool>> _pending = {};
  static String? _root;

  static Future<String> _dir() async =>
      _root ??= '${(await getApplicationSupportDirectory()).path}/audio';

  /// Kitabın sesi indirilmiş mi?
  static Future<bool> isReady(String bookId) async => File('${await _dir()}/$bookId/.ok').exists();

  /// Ses dosyasının telefondaki yolu; kitap indirilmemişse ya da dosya yoksa null.
  static Future<String?> fileFor(String bookId, String fileName) async {
    final file = File('${await _dir()}/$bookId/$fileName');
    return await file.exists() ? file.path : null;
  }

  /// Kitabın sesini indirir (aynı anda bir kez); başarılıysa true.
  static Future<bool> ensure(String bookId) =>
      _pending[bookId] ??= _download(bookId).whenComplete(() => _pending.remove(bookId));

  static Future<bool> _download(String bookId) async {
    if (await isReady(bookId)) return true;
    final dir = '${await _dir()}/$bookId';
    final part = File('$dir.zip.part');
    try {
      await part.parent.create(recursive: true);
      await FirebaseStorage.instance.ref('audio/$bookId.zip').writeToFile(part);
      final bytes = await part.readAsBytes();
      await Isolate.run(() => _extract(bytes, dir));
      await File('$dir/.ok').writeAsString('1');
      return true;
    } catch (e) {
      debugPrint('🔇 [AudioPacks] $bookId indirilemedi: $e');
      return false;
    } finally {
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
    }
  }

  static void _extract(Uint8List bytes, String dir) {
    Directory(dir).createSync(recursive: true);
    for (final f in ZipDecoder().decodeBytes(bytes).files) {
      if (!f.isFile) continue;
      // Yalnız dosya adı: arşivdeki yol klasör dışına yazdırmasın
      final name = f.name.split('/').last.split('\\').last;
      File('$dir/$name').writeAsBytesSync(f.content);
    }
  }
}
