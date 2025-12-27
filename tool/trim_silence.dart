import 'dart:io';

/// Sequential Script with Aggressive Tuning for Trimming Silence.
/// Using -40dB threshold to cut closer to the actual speech.
void main(List<String> args) async {
  if (args.isEmpty) {
    print("❌ Lütfen kitap ID'sini parametre olarak girin.");
    print("Örnek: dart tool/trim_silence.dart aglayan_deve");
    return;
  }

  final String bookId = args[0];
  final Directory audioDir = Directory('assets/audio/$bookId');
  if (!audioDir.existsSync()) {
      print("❌ Klasör bulunamadı: ${audioDir.path}");
      return;
  }

  final files = audioDir.listSync().where((f) => f.path.endsWith('.mp3')).toList();
  print("Found ${files.length} files. Starting aggressive trimming (-40dB)...");

  final stopwatch = Stopwatch()..start();
  int success = 0;
  int skipped = 0;

  for (int i = 0; i < files.length; i++) {
    final file = files[i];
    final String inputPath = file.path;
    final String outputPath = inputPath.replaceAll('.mp3', '_aggressive.mp3');

    try {
      // ffmpeg command to trim silence AGGRESSIVELY
      // start_threshold=-40dB: treats anything quieter than -40dB as silence (standard silence is -60dB)
      // This ensures we skip faint noise/breaths at the start
      final result = await Process.run('ffmpeg', [
        '-y', '-i', inputPath, 
        '-af', 'silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0', 
        outputPath
      ]);

      if (result.exitCode == 0) {
        try {
          final trimmedFile = File(outputPath);
          if (trimmedFile.lengthSync() > 500) { // Safety check (very short files might be errors)
             // Force delete original to avoid lock issues if possible (though generic Windows lock might persist)
             try {
               if (File(inputPath).existsSync()) File(inputPath).deleteSync();
             } catch (e) {
               // If delete fails, try simple rename or wait
             }
             
             trimmedFile.renameSync(inputPath);
             success++;
          } else {
             print("Warning: Trimmed file too small for ${file.path}, keeping original.");
             trimmedFile.deleteSync();
             skipped++;
          }
        } catch (e) {
          skipped++;
          if (File(outputPath).existsSync()) File(outputPath).deleteSync();
        }
      } else {
        skipped++;
      }
    } catch (e) {
      skipped++;
    }

    if ((i + 1) % 50 == 0) {
      print("Progress: ${i + 1}/${files.length}");
    }
  }

  print("\n✨ Aggressive Trim Done! Success: $success, Skipped: $skipped in ${stopwatch.elapsed.inSeconds}s.");
}
