import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';
import '../widgets/search_result_card.dart';
import '../services/saved_words_service.dart';
import '../services/credits_service.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback? onSavedWordsTabRequested;
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;

  const MainScreen({
    super.key,
    this.onSavedWordsTabRequested,
    this.isDarkMode = false,
    this.onThemeToggle,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SavedWordsService _savedWordsService = SavedWordsService();
  final CreditsService _creditsService = CreditsService();
  List<WordModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _savedWordsService.initialize();
    _creditsService.initialize();
    
    // CreditsService'i dinle
    _creditsService.addListener(_updateCredits);
  }
  
  void _requestKeyboardFocus() {
    if (!mounted) return;
    
    // Focus'u kaldır ve tekrar ver (bazen çalışması için gerekli)
    _searchFocusNode.unfocus();
    
    // Kısa bir gecikme ile focus'u tekrar ver
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
        debugPrint('🔤 Klavye focus isteği gönderildi');
      }
    });
  }
  
  void _updateCredits() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _creditsService.removeListener(_updateCredits);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Test verisi - yeni veri yapısına göre
    if (query.toLowerCase().contains('تهنئة') || query.toLowerCase().contains('tebrik')) {
      final testWord = WordModel(
        kelime: 'تهنئة',
        harekeliKelime: 'تَهْنِئَةٌ',
        anlam: 'Tebrik, kutlama',
        koku: 'هنا',
        dilbilgiselOzellikler: {
          'tur': 'Mastar',
          'cogulForm': 'تَهَانِئُ'
        },
          'maziForm': 'هَنَّأَ',
          'muzariForm': 'يُهَنِّئُ',
          'mastarForm': 'تَهْنِئَةٌ',
          'emirForm': 'هَنِّئْ'
        },
        ornekCumleler: [
          {
            'arapcaCumle': 'أَرْسَلْتُ تَهْنِئَةً بِالنَّجَاحِ.',
            'turkceCeviri': 'Başarı için tebrik mesajı gönderdim.'
          },
          {
            'arapcaCumle': 'تَلَقَّيْتُ تَهْنِئَةً بِالْعِيدِ.',
            'turkceCeviri': 'Bayram tebriği aldım.'
          }
        ],
        bulunduMu: true,
      };

      setState(() {
        _searchResults = [testWord];
        _isLoading = false;
      });
      return;
    }

    // Diğer test verileri...
    final mockResults = [
      WordModel(
        kelime: 'كتاب',
        harekeliKelime: 'كِتَابٌ',
        anlam: 'Kitap',
        koku: 'كتب',
        dilbilgiselOzellikler: {
          'tur': 'İsim',
          'cogulForm': 'كُتُبٌ'
        },
        ornekCumleler: [
          {
            'arapcaCumle': 'قَرَأْتُ الْكِتَابَ.',
            'turkceCeviri': 'Kitabı okudum.'
          }
        ],
        bulunduMu: true,
      ),
      WordModel(
        kelime: 'قرأ',
        harekeliKelime: 'قَرَأَ',
        anlam: 'Okumak',
        koku: 'قرأ',
        dilbilgiselOzellikler: {
          'tur': 'Fiil'
        },
        fiilCekimler: {
          'maziForm': 'قَرَأَ',
          'muzariForm': 'يَقْرَأُ',
          'mastarForm': 'قِرَاءَةٌ',
          'emirForm': 'اِقْرَأْ'
        },
        ornekCumleler: [
          {
            'arapcaCumle': 'يَقْرَأُ الطَّالِبُ الدَّرْسَ.',
            'turkceCeviri': 'Öğrenci dersi okuyor.'
          }
        ],
        bulunduMu: true,
      ),
    ];

    // Basit arama simülasyonu
    final filteredResults = mockResults.where((word) {
      final searchTerm = query.toLowerCase();
      return word.kelime.toLowerCase().contains(searchTerm) ||
             word.harekeliKelime?.toLowerCase().contains(searchTerm) == true ||
             word.anlam?.toLowerCase().contains(searchTerm) == true;
    }).toList();

    // Arama sonuçlarını skorlayarak sırala
    filteredResults.sort((a, b) => b.searchScore(query).compareTo(a.searchScore(query)));

    setState(() {
      _searchResults = filteredResults;
      _isLoading = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isLoading = false;
    });
  }

  void _selectWord(WordModel word) {
    // Kelime seçildiğinde yapılacak işlemler
    print('Kelime seçildi: ${word.kelime}');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF000000) 
          : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Başlık ve arama çubuğu
            Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: Column(
                children: [
                  // Başlık ve hak göstergesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kavaid',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      // Hak göstergesi
                      if (!_creditsService.isPremium) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _creditsService.credits <= 10 
                                ? Colors.red.withOpacity(0.1)
                                : (isDarkMode 
                                    ? const Color(0xFF007AFF).withOpacity(0.1)
                                    : const Color(0xFF007AFF).withOpacity(0.08)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _creditsService.credits <= 10
                                  ? Colors.red.withOpacity(0.3)
                                  : (isDarkMode 
                                      ? const Color(0xFF007AFF).withOpacity(0.3)
                                      : const Color(0xFF007AFF).withOpacity(0.2)),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: _creditsService.credits <= 10
                                    ? Colors.red
                                    : const Color(0xFF007AFF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_creditsService.credits} Hak',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _creditsService.credits <= 10
                                      ? Colors.red
                                      : const Color(0xFF007AFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Arama çubuğu
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDarkMode 
                                ? const Color(0xFF1C1C1E) 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDarkMode 
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode 
                                    ? Colors.black.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.02),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: false,
                            // Klavye performans optimizasyonları
                            enableInteractiveSelection: true,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.search,
                            autocorrect: false,
                            enableSuggestions: false,
                            smartDashesType: SmartDashesType.disabled,
                            smartQuotesType: SmartQuotesType.disabled,
                            onChanged: _performSearch,
                            onSubmitted: (value) {
                              // Enter tuşuna basıldığında da arama yap
                              _performSearch(value);
                            },
{{ ... }}
                              fontSize: 11,
                              color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Kelime ara',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: isDarkMode 
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6D6D70),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 14,
                                color: isDarkMode 
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6D6D70),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: _clearSearch,
                                      icon: Icon(
                                        Icons.clear,
                                        size: 12,
                                        color: isDarkMode 
                                            ? const Color(0xFF8E8E93)
                                            : const Color(0xFF6D6D70),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onThemeToggle != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: widget.onThemeToggle,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 28,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDarkMode 
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E5EA),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.isDarkMode 
                                  ? Icons.dark_mode 
                                  : Icons.light_mode,
                              size: 12,
                              color: isDarkMode 
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6D6D70),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Arama sonuçları
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF007AFF),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 48,
                                color: isDarkMode 
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6D6D70),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Aramaya başlamak için kelime yazın'
                                    : 'Sonuç bulunamadı',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode 
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF6D6D70),
                                ),
                              ),
                              if (_searchController.text.isEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Test için "تهنئة" veya "tebrik" yazın',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode 
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6D6D70),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final word = _searchResults[index];
                            return SearchResultCard(
                              word: word,
                              onTap: () => _selectWord(word),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
} 