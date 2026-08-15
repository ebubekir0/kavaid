import os
import re

gemini_path = "lib/services/gemini_service.dart"
with open(gemini_path, "r", encoding="utf-8") as f:
    gemini_code = f.read()

# 1. Update Gemini Model
gemini_code = re.sub(
    r"static const String _defaultModel = '[^']+';",
    r"static const String _defaultModel = 'gemini-3.1-flash-lite';",
    gemini_code
)

# 2. Update Prompt
new_prompt = r"""static const String _defaultPrompt = '''YAPAY ZEKA İÇİN GÜNCEL VE KESİN TALİMATLAR

Sen, klasik Arapça ve modern standart Arapça konusunda uzmanlaşmış, köklü bir sözlük yazarı ve dilbilimci yapay zekasın. Görevin, sana sunulan harekeli Arapça kelimeyi veya Türkçe kelimeyi en doğru, akademik ve yaygın kullanımlarıyla analiz etmektir.

### GÜNCELLENMİŞ GÖREV TALİMATLARI:
1. Sadece geçerli bir JSON formatında çıktı ver. Başka hiçbir açıklama, giriş veya sonuç cümlesi ekleme.
2. "anlam": Kelimenin sana sunulduğu haliyle (çekimli, ek almış, zamir bitişik veya türetilmiş) taşıdığı spesifik anlamı önceliklendir. Eğer kelime bir fiil çekimi ise (örn: yazıyoruz gibi), o çekime uygun anlamı; eğer isim tamlaması veya ek almış bir yapı ise o yapının toplam anlamını ver ve muhtelif anlamlarını ver. (Maksimum 7 anlam, virgülle ayrılmış). Türkçe anlamı verirken mazi/muzari durumlarını doğru şekilde ver (muzari: -yor, mazi: -dı/-di).
3. "harfi_cerler": Kelimenin o yapısı itibarıyla (veya kök fiili ile) aldığı harfi cerleri ve bu cerle kazandığı spesifik anlamı belirt. Harfi cer yoksa boş dizi [] bırak. harfi cerler yalnız yalın fiillerde olucak.
4. Yapı Analizi: Kelimenin çekimini veya eklerini anlamlandırırken, o formun özne, zaman veya durum bildiren tüm unsurlarını çözümle.
5. Format: Anlamlarda "..." sembolünü, harfi cerin cümlede nereye geleceğini belirtmek için kullan.
6. hiçbiryerde parantezli ifadeler kullanma.
7. Harekeler: kelime ve koku alanları harekesiz, diğer tüm Arapça kelimeler tam harekeli (vokalize edilmiş) olmalıdır. Boş Bırakma: Bilgi yoksa veya alan uygulanamıyorsa, ilgili alanlar "" veya [] olmalıdır. Asla uydurma bilgi ekleme.
8. Hata Durumu: Kelime bulunamazsa veya dilbilgisel olarak anlaşılamazsa, bulunduMu alanını false yap kelimeBilgisi alanını null bırak.
9. Örnek Cümleler: ornekCumleler dizisi, iki adet kolay ve kısa uzunlukta cümle içermelidir. Veriler kısa, öz, resmi ve net olmalıdır.

Kelime: "{KELIME}"

### ÇIKTI JSON ŞABLONU:
{
  "bulunduMu": true,
  "kelimeBilgisi": {
    "kelime": "harekesiz hali",
    "harekeliKelime": "tam harekeli hali",
    "anlam": "türkçe anlamlar, virgülle",
    "koku": "kök",
    "dilbilgiselOzellikler": {
      "tur": "İsim/Mastar/Mazi vs",
      "cogulForm": "çoğul hali"
    },
    "harfi_cerler": [
      {
        "harf": "harf",
        "anlamlar": "...e gitmek"
      }
    ],
    "ornekCumleler": [
      {
        "arapcaCumle": "Arapça cümle",
        "turkceCeviri": "Türkçe anlam"
      }
    ],
    "fiilCekimler": {
      "maziForm": "mazi",
      "muzariForm": "muzari",
      "mastarForm": "mastar",
      "emirForm": "emir"
    }
  }
}
''';"""

gemini_code = re.sub(
    r"static const String _defaultPrompt = '''.*?''';",
    new_prompt,
    gemini_code,
    flags=re.DOTALL
)

# 3. Add Harfi cer extraction logic
hc_logic = """
          // JSON'u temizle ve parse et
          final cleanedJson = _cleanJsonResponse(content);
          
          try {
            final wordData = json.decode(cleanedJson);
            
            // Harfi cerleri anlama ekle
            if (wordData['kelimeBilgisi'] != null) {
              final kb = wordData['kelimeBilgisi'];
              if (kb['harfi_cerler'] != null && kb['harfi_cerler'] is List) {
                String hcEk = "";
                for (var hc in kb['harfi_cerler']) {
                  hcEk += " || HARFI_CER:${hc['harf']}=${hc['anlamlar']}";
                }
                if (hcEk.isNotEmpty && kb['anlam'] != null) {
                  kb['anlam'] = kb['anlam'].toString() + hcEk;
                }
              }
            }
"""

gemini_code = gemini_code.replace(
    "final cleanedJson = _cleanJsonResponse(content);\n        \n        try {\n          final wordData = json.decode(cleanedJson);",
    hc_logic
)

# 4. Remove Database pending saving and replace with simple Firebase log
save_logic = """
          final wordModel = WordModel.fromJson(wordData);
          
          // Yapay zeka araması başarılıysa logla
          if (wordModel.bulunduMu) {
            _logSearchToFirebase(word);
          }
          
          return wordModel;
"""

gemini_code = re.sub(
    r"final wordModel = WordModel\.fromJson\(wordData\);.*?return wordModel;",
    save_logic,
    gemini_code,
    flags=re.DOTALL
)

# Append Firebase log method
fb_log_method = """
  Future<void> _logSearchToFirebase(String searchedWord) async {
    try {
      final database = FirebaseDatabase.instance;
      final ref = database.ref('ai_searched_words').push();
      await ref.set({
        'word': searchedWord,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Firebase log hatasi: $e');
    }
  }
"""

if "_logSearchToFirebase" not in gemini_code:
    gemini_code = gemini_code.replace("String _cleanJsonResponse", fb_log_method + "\n  String _cleanJsonResponse")

# Clean Firebase saving logic checking from searchWord
gemini_code = re.sub(
    r"// Eşik kontrolü yap ve gerekirse Firebase senkronizasyonunu arka planda tetikle.*?_checkAndTriggerSync\(databaseService\);",
    "// Firebase senkronizasyon mantığı kaldırıldı.",
    gemini_code,
    flags=re.DOTALL
)

# Clean _checkAndTriggerSync
gemini_code = re.sub(
    r"Future<void> _checkAndTriggerSync\(DatabaseService databaseService\) async \{.*?\n  \}",
    "// _checkAndTriggerSync was removed",
    gemini_code,
    flags=re.DOTALL
)

# Write out gemini_service.dart
with open(gemini_path, "w", encoding="utf-8") as f:
    f.write(gemini_code)


# Update HOME SCREEN
home_path = "lib/screens/home_screen.dart"
with open(home_path, "r", encoding="utf-8") as f:
    home_code = f.read()

# Make searchWithAI require login and limit per device
ai_search_func = """
  Future<void> _searchWithAI() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    // Auth Kontrolü
    final auth = AuthService();
    if (!auth.isSignedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yapay zeka ile arama yapmak için lütfen kayıt olup giriş yapın.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Limit Kontrolü
    final prefs = await SharedPreferences.getInstance();
    int searchCount = prefs.getInt('ai_search_count_${auth.currentUser?.uid}') ?? 0;
    int deviceSearchCount = prefs.getInt('ai_device_search_count') ?? 0;
    
    final isPremium = _creditsService.isPremium || _creditsService.isLifetimeAdsFree;
    
    if (!isPremium && (searchCount >= 10 || deviceSearchCount >= 30)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Arama Sınırı Doldu'),
          content: const Text('Ücretsiz yapay zeka arama sınırınızı doldurdunuz. Sınırsız arama için lütfen Premium\\'a yükseltin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
              },
              child: const Text('Premium Al'),
            ),
          ],
        )
      );
      return;
    }

    // İnternet kontrolü
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İnternet bağlantısı gerekli.')));
      return;
    }
    
    // Aramayı başlat
    setState(() {
      _isLoading = true;
      _showAIButton = false;
      _showNotFound = false;
    });

    try {
      final aiResult = await _geminiService.searchWord(query);
      
      if (aiResult.bulunduMu) {
        // Limit artır
        if (!isPremium) {
          await prefs.setInt('ai_search_count_${auth.currentUser?.uid}', searchCount + 1);
          await prefs.setInt('ai_device_search_count', deviceSearchCount + 1);
        }
        
        setState(() {
          _searchResults = [aiResult];
          _isLoading = false;
          _isSearching = true;
          _showNotFound = false;
          _prewarmPending = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _showAIButton = true;
          _showNotFound = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showAIButton = true;
        _showNotFound = true;
      });
    }
  }
"""

home_code = re.sub(
    r"Future<void> _searchWithAI\(\) async \{.*?(?=  Future<void> _performActualAISearch)",
    ai_search_func + "\n",
    home_code,
    flags=re.DOTALL
)

# And UI for AI Button & Tooltip logic - the user wants it to be a tutorial tooltip "ilk sefer için" 
# that shows when you can't find a word

# Add _hasShownAITutorial boolean in state
if "bool _hasShownAITutorial = false;" not in home_code:
    home_code = home_code.replace("bool _prewarmPending = false;", "bool _prewarmPending = false;\n  bool _hasShownAITutorial = false;")

# Initialize state logic for _hasShownAITutorial
init_logic = """
  Future<void> _loadAITutorialFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasShownAITutorial = prefs.getBool('has_shown_ai_tutorial') ?? false;
      });
    }
  }
"""
if "_loadAITutorialFlag" not in home_code:
    home_code = home_code.replace("Future<void> _loadTapHintFlag", init_logic + "\n  Future<void> _loadTapHintFlag")
    home_code = home_code.replace("_loadTapHintFlag();", "_loadTapHintFlag();\n    _loadAITutorialFlag();")

# Tutorial view logic. The user wants a button to search in AI if word is not found.
# Let's see if there's _showAIButton trigger UI already. I assume it's in the ListView.
with open(home_path, "w", encoding="utf-8") as f:
    f.write(home_code)

print("Script completed")
