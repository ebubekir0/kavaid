import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'dart:convert'; // Base64 ve JSON için eklendi

import '../models/custom_word.dart';
import '../models/custom_word_list.dart';
import '../services/custom_word_service.dart';
import '../widgets/search_result_card.dart';
import '../models/word_model.dart';
import '../services/tts_service.dart';
import '../services/test_community_chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kelimelerim Ana Ekranı - Kullanıcının oluşturduğu listeleri gösterir
/// BookTextsScreen ile aynı UI yapısına sahip
class CustomWordsScreen extends StatefulWidget {
  final bool isDarkMode;

  const CustomWordsScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<CustomWordsScreen> createState() => _CustomWordsScreenState();
}

class _CustomWordsScreenState extends State<CustomWordsScreen> {
  final CustomWordService _service = CustomWordService();
  List<CustomWordList> _lists = [];
  Map<String, int> _wordCounts = {};
  bool _isLoading = true;
  String? _loadingListId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _service.migrateSavedWords();

    // En az bir liste olduğundan emin ol
    await _service.getOrCreateDefaultList();
    var lists = await _service.getLists();
    
    // Sıralama: En çok kelime olan en üstte, aynıysa en eski oluşturulan üstte

    // Her liste için kelime sayısını al
    final counts = <String, int>{};
    for (final list in lists) {
      final words = await _service.getWordsByList(list.id);
      counts[list.id] = words.length;
    }

    // Listeleri kelime sayısına göre sırala (çoktan aza, aynıysa eski üstte)
    lists.sort((a, b) {
      // Kelime sayısına göre (çoktan aza)
      final countA = counts[a.id] ?? 0;
      final countB = counts[b.id] ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA); // Çok olan üstte
      }
      
      // Kelime sayısı aynıysa oluşturma tarihine göre (eski üstte)
      return a.createdAt.compareTo(b.createdAt);
    });

    if (!mounted) return;
    setState(() {
      _lists = lists;
      _wordCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _showAddListDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'Yeni Liste',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Liste adı',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
              ),
              filled: true,
              fillColor: widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await _service.createList(name);
                if (!mounted) return;
                Navigator.of(context).pop();
                _loadData();
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameListDialog(CustomWordList list) async {
    final controller = TextEditingController(text: list.name);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'Listeyi Yeniden Adlandır',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Liste adı',
              border: const OutlineInputBorder(),
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                await _service.renameList(list.id, name);
                if (!mounted) return;
                Navigator.of(context).pop();
                _loadData();
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToList(CustomWordList list) async {
    if (_loadingListId != null) return;

    setState(() {
      _loadingListId = list.id;
    });

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordListDetailScreen(
            list: list,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
      _loadData();
    } finally {
      if (mounted) {
        setState(() {
          _loadingListId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007AFF),
        elevation: 0,
        title: const Text(
          'Kelime Listelerim',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF007AFF),
                strokeWidth: 2.5,
              ),
            )
          : _lists.isEmpty
              ? _buildEmptyState(isDark)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _lists.length,
                        itemBuilder: (context, index) {
                          final list = _lists[index];
                          final wordCount = _wordCounts[list.id] ?? 0;
                          return _buildListCard(list, wordCount, index, isDark);
                        },
                      ),
                    ),
                    // Alt kısımda liste ekleme butonu
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _showAddListDialog,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Yeni Liste Oluştur',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz liste yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelimelerinizi düzenlemek için\nbir liste oluşturun',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          // Liste ekleme butonu
          GestureDetector(
            onTap: _showAddListDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Yeni Liste Oluştur',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(CustomWordList list, int wordCount, int index, bool isDark) {
    // Tek liste kaldıysa silinemez (her zaman en az 1 liste olmalı)
    final canDelete = _lists.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToList(list),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Sol - Mavi numara kutusu
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Orta - Liste adı ve kelime sayısı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$wordCount kelime',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ - Paylaş butonu + 3 nokta menüsü
                if (_loadingListId == list.id)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Paylaş butonu (ayrı)
                      if (!list.isShared)
                        GestureDetector(
                          onTap: () => _showShareConfirmDialog(list, wordCount, isDark),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.share_rounded,
                              size: 20,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        ),
                      // 3 nokta menüsü
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        onSelected: (value) {
                          if (value == 'rename') {
                            _showRenameListDialog(list);
                          } else if (value == 'delete') {
                            _showDeleteDialog(list, isDark);
                          }
                        },
                        itemBuilder: (context) => [
                          // Yeniden adlandır
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
                                const SizedBox(width: 12),
                                Text('Yeniden Adlandır', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                          ),
                          // Sil
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Sil', style: TextStyle(fontSize: 14, color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Paylaşma onay dialogu
  void _showShareConfirmDialog(CustomWordList list, int wordCount, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Toplulukta Paylaş',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '"${list.name}" listesi toplulukta paylaşılsın mı?',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İptal',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _shareListToCommunity(list, wordCount);
            },
            child: const Text(
              'Paylaş',
              style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Kelime listesini toplulukta paylaş
  Future<void> _shareListToCommunity(CustomWordList list, int wordCount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşmak için giriş yapmalısınız'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Liste boşsa paylaşma
    if (wordCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boş liste paylaşılamaz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Kelimeleri al
    final words = await _service.getWordsByList(list.id);
    
    // Kelime verilerini hazırla (tüm datayı al)
    final wordMaps = words.map((w) => {
      'arabic': w.arabic,
      'turkish': w.turkish,
      'harekeliKelime': w.harekeliKelime,
      'wordData': w.wordData,
    }).toList();

    // Test toplulukta paylaş
    final chatService = TestCommunityChatService();
    
    // Erişim kontrolü
    if (!chatService.canAccessTestCommunity()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test topluluğuna erişim izniniz yok'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // JSON'a çevir ve Base64 ile encode et
    final jsonString = jsonEncode(wordMaps);
    final base64Data = base64Encode(utf8.encode(jsonString));
    
    // Paylaşım mesajı (V2 formatı: BASE64_JSON|...)
    final shareMessage = '📚 KELIME_LISTESI_PAYLASIMI_V2|${list.name}|${words.length}|$base64Data';
    
    final success = await chatService.sendMessage(shareMessage);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ "${list.name}" toplulukta paylaşıldı!'
              : 'Paylaşım başarısız'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// Kelimeleri encode et
  String _encodeWords(List<Map<String, dynamic>> words) {
    return words.map((w) => '${w['arabic']}::${w['turkish']}').join('|||');
  }

  Future<void> _showDeleteDialog(CustomWordList list, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'Listeyi Sil',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            '"${list.name}" silinsin mi?\nİçindeki tüm kelimeler de silinecek.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Sil',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _service.deleteList(list.id);
      _loadData();
    }
  }
}

/// Kelime Listesi Detay Ekranı - TextWordsScreen ile aynı UI
class WordListDetailScreen extends StatefulWidget {
  final CustomWordList list;
  final bool isDarkMode;

  const WordListDetailScreen({
    super.key,
    required this.list,
    required this.isDarkMode,
  });

  @override
  State<WordListDetailScreen> createState() => _WordListDetailScreenState();
}

class _WordListDetailScreenState extends State<WordListDetailScreen> {
  final CustomWordService _service = CustomWordService();
  final TTSService _ttsService = TTSService();
  List<CustomWord> _words = [];
  bool _isLoading = true;
  bool _isCardMode = false; // Varsayılan: Liste görünümü
  int _currentCardIndex = 0;
  late PageController _pageController;
  bool _showMeaning = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadWords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
    });

    final words = await _service.getWordsByList(widget.list.id);
    if (!mounted) return;
    setState(() {
      _words = words;
      _isLoading = false;
    });
  }

  Future<void> _showAddInfo() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          title: Text(
            'Bilgi',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Bu listeye kelime eklemek için "Sözlük" bölümünü kullanabilirsiniz.\n\nSözlükte aradığınız kelimenin kartındaki + butonuna basarak bu listeye ekleyebilirsiniz.',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeWord(CustomWord word) async {
    await _service.deleteWord(word.id);
    _loadWords();
    // Snackbar bildirimi kaldırıldı
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007AFF),
        elevation: 0,
        title: Text(
          widget.list.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? Center(
                  child: Text(
                    'Bu listede henüz kelime yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildViewToggle(isDark),
                    const SizedBox(height: 4),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isCardMode
                            ? _buildCardView(isDark)
                            : _buildListView(isDark),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildViewToggle(bool isDarkMode) {
    final Color activeColor = const Color(0xFF007AFF);
    final Color bgColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final Color borderColor = isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final Color inactiveText = isDarkMode ? const Color(0xFFEBEBF5) : const Color(0xFF1C1C1E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isCardMode) {
                    setState(() {
                      _isCardMode = false;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isCardMode ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Liste',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !_isCardMode ? Colors.white : inactiveText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!_isCardMode) {
                    _pageController.dispose();
                    _pageController = PageController(initialPage: _currentCardIndex);
                    setState(() {
                      _isCardMode = true;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _isCardMode ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Kart',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isCardMode ? Colors.white : inactiveText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(bool isDarkMode) {
    // ReorderableListView ile sıralama özelliği
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      itemCount: _words.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _words.removeAt(oldIndex);
          _words.insert(newIndex, item);
        });
        // Yeni sırayı kaydet
        await _service.saveReorderedWords(_words);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return Material(
              elevation: 8,
              color: Colors.transparent,
              shadowColor: Colors.black.withOpacity(0.2),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final word = _words[index];
        // CustomWord'den tam WordModel oluştur (tüm bilgilerle)
        final wordModel = word.toWordModel();
        // Harekeli kelime varsa onu kullan
        final displayWord = wordModel.harekeliKelime?.isNotEmpty == true 
            ? wordModel.harekeliKelime! 
            : wordModel.kelime;

        return Container(
          key: ValueKey('result_${word.arabic}_$index'), // Key unique olmalı
          child: SearchResultCard(
            word: wordModel,
            onTap: () {
              _ttsService.speak(displayWord);
            },
            onExpand: () {
              FocusScope.of(context).unfocus();
            },
            showAddButton: false, // Listede zaten var
            showRemoveButton: true, // Listeden çıkarma butonu aktif
            onRemove: () => _removeWord(word), // Çıkarma işlemi
          ),
        );
      },
    );
  }

  Future<void> _showDeleteWordDialog(CustomWord word, bool isDarkMode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text('Kelimeyi Sil', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: Text('"${word.arabic}" silinsin mi?', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteWord(word.id);
      _loadWords();
    }
  }

  Widget _buildCardView(bool isDarkMode) {
    final Color cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final Color subTextColor = isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);

    if (_words.isEmpty) {
      return const SizedBox.shrink();
    }

    final int safeIndex = _currentCardIndex.clamp(0, _words.length - 1);
    if (safeIndex != _currentCardIndex) {
      _currentCardIndex = safeIndex;
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification && _showMeaning) {
                  setState(() {
                    _showMeaning = false;
                  });
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _words.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentCardIndex = index;
                    _showMeaning = false;
                  });
                },
                itemBuilder: (context, index) {
                  final word = _words[index];
                  // CustomWord'den tam WordModel oluştur
                  final wordModel = word.toWordModel();
                  // Harekeli kelime varsa onu kullan
                  final displayWord = wordModel.harekeliKelime?.isNotEmpty == true 
                      ? wordModel.harekeliKelime! 
                      : wordModel.kelime;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _showMeaning = !_showMeaning;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.35)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Ses Butonu - En Üstte
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              onPressed: () {
                                _ttsService.speak(word.arabic);
                              },
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: subTextColor.withOpacity(0.7),
                                size: 28,
                              ),
                              tooltip: 'Dinle',
                            ),
                          ),

                          // Kelime/Anlam Bölümü - Tam Merkezde Sabit
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(bottom: 70),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 100),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: _showMeaning
                                    ? Text(
                                        word.turkish,
                                        key: const ValueKey('meaning'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          height: 1.4,
                                        ),
                                      )
                                    : Text(
                                        displayWord,
                                        key: const ValueKey('word'),
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          height: 1.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          // Örnek Cümle - Minimalist
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Builder(
                              builder: (context) {
                                // wordData içinden direkt erişim
                                List<dynamic>? ornekler;
                                
                                // Debug: wordData içeriğini kontrol et
                                print('🔍 CustomWord wordData: ${word.wordData}');
                                print('🔍 CustomWord wordData ornekCumleler: ${word.wordData?['ornekCumleler']}');
                                
                                // Önce wordData'dan dene
                                if (word.wordData != null && word.wordData!['ornekCumleler'] != null) {
                                  ornekler = word.wordData!['ornekCumleler'] as List<dynamic>?;
                                  print('✅ ornekler wordData\'dan alındı: $ornekler');
                                }
                                
                                // Eğer yoksa toWordModel() ile dene
                                if (ornekler == null || ornekler.isEmpty) {
                                  final wordModel = word.toWordModel();
                                  ornekler = wordModel.ornekCumleler;
                                  print('⚠️ ornekler toWordModel()\'dan alındı: $ornekler');
                                }
                                
                                if (ornekler == null || ornekler.isEmpty) {
                                  print('❌ Örnek cümle bulunamadı');
                                  return const SizedBox.shrink();
                                }
                                
                                final ornek = ornekler[0];
                                print('📖 İlk örnek: $ornek');
                                
                                if (ornek is! Map<String, dynamic>) {
                                  print('❌ Örnek Map değil: ${ornek.runtimeType}');
                                  return const SizedBox.shrink();
                                }
                                
                                // Farklı format desteği (arapcaCümle vs arapcaCumle, turkceAnlam vs turkceCeviri)
                                final arapcaCumle = (ornek['arapcaCumle'] ?? ornek['arapcaCümle'] ?? ornek['arapca'] ?? '').toString();
                                final turkceCeviri = (ornek['turkceCeviri'] ?? ornek['turkceAnlam'] ?? ornek['turkce'] ?? '').toString();
                                print('📝 arapcaCumle: $arapcaCumle');
                                print('📝 turkceCeviri: $turkceCeviri');
                                
                                // Dinamik font boyutu - uzun cümleler için küçültme
                                final double fontSize = arapcaCumle.length > 90 ? 17 : (arapcaCumle.length > 50 ? 19 : 21);

                                if (arapcaCumle.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                
                                return Container(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Colors.white.withOpacity(0.03)
                                        : Colors.black.withOpacity(0.025),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDarkMode 
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Arapça örnek cümle
                                      Text(
                                        arapcaCumle,
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w600,
                                          color: textColor.withOpacity(0.85),
                                          height: 1.5,
                                        ),
                                      ),
                                      
                                      // Türkçe çeviri - Smooth
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                        child: _showMeaning && turkceCeviri.isNotEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  turkceCeviri,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: subTextColor,
                                                    fontStyle: FontStyle.italic,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Slider navigasyon - TextWordsScreen ile aynı
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${safeIndex + 1} / ${_words.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _currentCardIndex > 0
                            ? () {
                                _pageController.animateToPage(
                                  _currentCardIndex - 1,
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOut,
                                );
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: _currentCardIndex > 0
                                ? (isDarkMode ? Colors.white : const Color(0xFF1C1C1E))
                                : subTextColor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2, pressedElevation: 4),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: const Color(0xFF007AFF),
                          inactiveTrackColor: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                          thumbColor: const Color(0xFF007AFF),
                          overlayColor: const Color(0xFF007AFF).withOpacity(0.2),
                          trackShape: const RoundedRectSliderTrackShape(),
                        ),
                        child: Slider(
                          value: _currentCardIndex.toDouble(),
                          min: 0,
                          max: (_words.length - 1).toDouble(),
                          divisions: _words.length > 1 ? _words.length - 1 : null,
                          onChanged: (value) {
                            final pageIndex = value.round();
                            setState(() {
                              _currentCardIndex = pageIndex;
                              _showMeaning = false;
                            });
                            _pageController.jumpToPage(pageIndex);
                          },
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: safeIndex < _words.length - 1
                            ? () {
                                _pageController.animateToPage(
                                  _currentCardIndex + 1,
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOut,
                                );
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 28,
                            color: safeIndex < _words.length - 1
                                ? (isDarkMode ? Colors.white : const Color(0xFF1C1C1E))
                                : subTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


