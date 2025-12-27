import 'dart:io';

const books = [
  'romeo_ve_juliet',
  'titanik',
  'donusum_kafka',
  'barbaros_hayrettin',
  'savas_ve_baris',
  'babil_asma_bahceleri',
  'imam_gazali',
  'frankenstein'
];

void main() async {
  print("🔥 DOWNLOAD & TRIM STARTED FOR 8 NEW BOOKS 🔥");
  
  // 1. DELETE EXISTING AUDIO FILES (Clean slate for new books)
  print("\n🗑️  Deleting existing audio files...");
  for (var bookId in books) {
    final dir = Directory('assets/audio/$bookId');
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
        print("   Deleted: ${dir.path}");
      } catch (e) {
        print("   Error deleting ${dir.path}: $e");
      }
    }
  }

  // 2. RUN DOWNLOAD SCRIPT FOR EACH BOOK
  print("\n⬇️  Starting Download loop for 10 books...");
  
  for (final bookId in books) {
      print("\n📘 Downloading: $bookId");
      // Call download_book_audio.dart with bookId argument
      final result = await Process.run('dart', ['tool/download_book_audio.dart', bookId]);
      
      if (result.exitCode == 0) {
          // Print only summary lines to avoid spam
          final lines = result.stdout.toString().split('\n');
          for (var line in lines) {
             if (line.contains('Başarılı') || line.contains('Hata')) print("   $line");
          }
      } else {
          print("❌ Failed to download $bookId");
          print(result.stderr);
      }
  }

  print("\n✅ All Downloads Completed. Starting Trim...");

  // 3. TRIM SILENCE (ONLY FROM START, -40dB)
  final stopwatch = Stopwatch()..start();
  int totalTrimmed = 0;
  
  for (final bookId in books) {
    print("\n✂️  Trimming Book: $bookId");
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

    print("   Found ${files.length} audio files. Applying correct trim...");
    int bookProcessed = 0;

    for (final file in files) {
      final String inputPath = file.path;
      final String tempPath = inputPath.replaceAll('.mp3', '_temp.mp3');

      try {
        // FFmpeg: ONLY remove silence from START.
        // start_periods=1: remove silence from beginning only.
        // start_threshold=-40dB: silence threshold.
        // start_silence=0: keep 0s of silence (cut immediately).
        // REMOVED stop_periods (no end trimming).
        final result = await Process.run('ffmpeg', [
          '-y', '-i', inputPath, 
          '-af', 'silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0', 
          tempPath
        ]);

        if (result.exitCode == 0) {
          final tempFile = File(tempPath);
          if (tempFile.lengthSync() > 0) {
            File(inputPath).deleteSync();
            tempFile.renameSync(inputPath);
            bookProcessed++;
            totalTrimmed++;
          } else {
             if (tempFile.existsSync()) tempFile.deleteSync();
          }
        }
      } catch (e) {
        print("   Error trimming ${file.path}: $e");
      }
    }
    print("   ✅ $bookProcessed files processed.");
  }

  print("\n🎉 ALL TASKS COMPLETED! Total trimmed: $totalTrimmed files.");
}
