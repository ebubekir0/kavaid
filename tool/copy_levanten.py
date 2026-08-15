import os
import shutil

src_base = r"c:\Users\kul\Desktop\levanten\lib"
dst_base = r"c:\Users\kul\Desktop\kavaid1111\kavaid\lib\features\translation"

os.makedirs(dst_base, exist_ok=True)
os.makedirs(os.path.join(dst_base, "models"), exist_ok=True)
os.makedirs(os.path.join(dst_base, "providers"), exist_ok=True)
os.makedirs(os.path.join(dst_base, "services"), exist_ok=True)
os.makedirs(os.path.join(dst_base, "ui"), exist_ok=True)

# File mappings
files_to_copy = {
    r"models\language.dart": r"models\language.dart",
    r"providers\translation_provider.dart": r"providers\translation_provider.dart",
    r"services\consent_manager.dart": r"services\consent_manager.dart",
    r"services\data_collection_service.dart": r"services\data_collection_service.dart",
    r"services\device_info_collector.dart": r"services\device_info_collector.dart",
    r"services\gemini_service.dart": r"services\translation_gemini_service.dart",
    r"services\stt_service.dart": r"services\stt_service.dart",
    r"services\tts_service.dart": r"services\tts_service.dart",
    r"ui\screens\home_screen.dart": r"ui\translation_tab.dart",
}

for src_rel, dst_rel in files_to_copy.items():
    src_file = os.path.join(src_base, src_rel)
    dst_file = os.path.join(dst_base, dst_rel)
    print(f"Copying {src_file} -> {dst_file}")
    shutil.copy2(src_file, dst_file)
    
    # Read content
    with open(dst_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replacements
    # 1. Rename GeminiService class for translation
    content = content.replace("class GeminiService", "class TranslationGeminiService")
    content = content.replace("GeminiService()", "TranslationGeminiService()")
    content = content.replace("GeminiService _geminiService", "TranslationGeminiService _geminiService")
    content = content.replace("import '../services/gemini_service.dart';", "import '../services/translation_gemini_service.dart';")
    content = content.replace("import '../../services/gemini_service.dart';", "import '../../services/translation_gemini_service.dart';")
    
    # 2. Rename HomeScreen -> TranslationTab
    if dst_rel == r"ui\translation_tab.dart":
        content = content.replace("class HomeScreen", "class TranslationTab")
        content = content.replace("HomeScreen({super.key})", "TranslationTab({super.key})")
        content = content.replace("ConsumerState<HomeScreen>", "ConsumerState<TranslationTab>")
        content = content.replace("_HomeScreenState", "_TranslationTabState")
        
        # 3. Replace AppLocalizations because it might not exist in kavaid
        content = content.replace("import '../../l10n/app_localizations.dart';", "")
        content = content.replace("AppLocalizations.of(context).translate", "'Çevir'")
        content = content.replace("AppLocalizations.of(context).translateFrom", "'Şu Dilden Çevir'")
        content = content.replace("AppLocalizations.of(context).translateTo", "'Şu Dile Çevir'")
        content = content.replace("AppLocalizations.of(context).enterTextArabic", "'أدخل النص هنا'")
        content = content.replace("AppLocalizations.of(context).enterText", "'Metin girin'")
        
        # Fix imports for features/translation inside kavaid
        
    with open(dst_file, 'w', encoding='utf-8') as f:
        f.write(content)

print('Copy and transformation complete.')
