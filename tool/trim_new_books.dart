import 'dart:io';

const books = [
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

void main() async {
  print("🔥 TRIM BATCH STARTED FOR 10 BOOKS 🔥");

  final stopwatch = Stopwatch()..start();
  int totalTrimmed = 0;
  
  for (final bookId in books) {
    print("\n📘 Processing Book: $bookId");
    final Directory audioDir = Directory('assets/audio/$bookId');
    
    if (!audioDir.existsSync()) {
      print("❌ Directory not found: ${audioDir.path}");
      continue;
    }

    final files = audioDir.listSync().where((f) => f.path.endsWith('.mp3')).toList();
    if (files.isEmpty) {
      print("⚠️ No MP3 files found.");
      continue;
    }

    print("   Found ${files.length} audio files. Trimming...");
    int bookProcessed = 0;

    for (final file in files) {
      final String inputPath = file.path;
      final String tempPath = inputPath.replaceAll('.mp3', '_temp.mp3');

      try {
        // FFmpeg command: Trim silence from START (-40dB) and END (-40dB)
        // start_periods=1: remove silence from start
        // stop_periods=1: remove silence from end
        final result = await Process.run('ffmpeg', [
          '-y', '-i', inputPath, 
          '-af', 'silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0:stop_periods=1:stop_threshold=-40dB:stop_silence=0', 
          tempPath
        ]);

        if (result.exitCode == 0) {
          final tempFile = File(tempPath);
          if (tempFile.lengthSync() > 0) {
            // Delete original and rename temp to original
            File(inputPath).deleteSync();
            tempFile.renameSync(inputPath);
            bookProcessed++;
            totalTrimmed++;
          } else {
             // If output is empty (error), delete temp
             if (tempFile.existsSync()) tempFile.deleteSync();
          }
        }
      } catch (e) {
        print("   Error trimming ${file.path}: $e");
      }
    }
    print("   ✅ $bookProcessed files trimmed.");
  }

  print("\n🎉 BATCH COMPLETED! Total trimmed: $totalTrimmed files in ${stopwatch.elapsed.inMinutes} minutes.");
}
