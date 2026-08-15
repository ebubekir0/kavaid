import os
import re

home_path = "lib/screens/home_screen.dart"
with open(home_path, "r", encoding="utf-8") as f:
    home_code = f.read()

# Add _hasShownAITutorial boolean
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

# The method that checks and shows the tutorial snackbar
ai_tutorial_method = """
  void _showAITutorialIfNeeded() {
    if (!_hasShownAITutorial && mounted) {
      _hasShownAITutorial = true;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('has_shown_ai_tutorial', true);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aradığın kelime sözlükte bulunamazsa yapay zeka ile aramayı deneyebilirsin.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF007AFF),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
"""

if "_showAITutorialIfNeeded" not in home_code:
    home_code = home_code.replace("void _removeTapHintOverlay", ai_tutorial_method + "\n  void _removeTapHintOverlay")

# Trigger it in _performSearch where _searchResults = [] and _showAIButton = true is set
search_trigger = """
        // Normal sözlükte ara
        final results = await _dbService.searchWords(cleanQuery);

        if (mounted) {
          final currentText = _searchController.text.trim();
          if (currentText != cleanQuery) return;

          setState(() {
            _searchResults = results;
            // Kuran sonuçlarını silme!
            _isLoading = false;
            _selectedWord = null;
            _showAIButton = true;
            _showNotFound = false;
            _isSearchInProgress = false;
          });
          
          // Eğer kelime bulunamadıysa yapay zeka butonunu ilk kez gösteriyorsak tutorial ver
          if (results.isEmpty) {
            _showAITutorialIfNeeded();
          }
        }
"""
home_code = re.sub(
    r"// Normal sözlükte ara\s+final results = await _dbService\.searchWords\([^)]+\);\s+if \(mounted\) \{\s+final currentText = _searchController\.text\.trim\(\);\s+if \(currentText != cleanQuery\) return;\s+setState\(\{\s+_searchResults = results;\s+// Kuran sonuçlarını silme!\s+_isLoading = false;\s+_selectedWord = null;\s+_showAIButton = true;\s+_showNotFound = false;\s+_isSearchInProgress = false;\s+\}\);\s+\}",
    search_trigger,
    home_code,
    flags=re.DOTALL
)

with open(home_path, "w", encoding="utf-8") as f:
    f.write(home_code)

print("Tutorial logic updated")
