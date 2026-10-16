// Sözlük kartının (SearchResultCard) görsel parçaları. Servis bağımlılığı
// yoktur; yalnızca kelime verisinden çizim yapar, bu yüzden testte tek
// başına çizilebilir.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/word_model.dart';
import '../services/language_service.dart';
import '../services/search_ranking.dart' show foldTurkishChar;

const _blue = Color(0xFF007AFF);
const _arabicFeatures = [
  ui.FontFeature.enable('liga'),
  ui.FontFeature.enable('calt'),
];

/// Kartta kullanılan Arapça yazı stilleri (yerel ScheherazadeNew fontu).
class ArabicTextStyles {
  ArabicTextStyles._();

  /// Kartın başlığındaki harekeli kelime.
  static const word = TextStyle(
    fontFamily: 'ScheherazadeNew',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    fontFeatures: _arabicFeatures,
  );

  /// Kelimenin yanındaki kök: kelimeden biraz küçük, soluk renkte.
  static const root = TextStyle(
    fontFamily: 'ScheherazadeNew',
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Örnek cümle.
  static const example = TextStyle(
    fontFamily: 'ScheherazadeNew',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.6,
    fontFeatures: _arabicFeatures,
  );

  /// Çoğul ve fiil çekimi kutularındaki kelime.
  static const form = TextStyle(
    fontFamily: 'ScheherazadeNew',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFeatures: _arabicFeatures,
  );
}

Color _primaryText(bool isDarkMode) =>
    isDarkMode ? Colors.white : const Color(0xFF1C1C1E);

Color _secondaryText(bool isDarkMode) =>
    isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);

/// Genişleyen alandaki bölümlerin ortak zemini.
BoxDecoration _sectionDecoration(bool isDarkMode) => BoxDecoration(
  color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF5F6F8),
  borderRadius: BorderRadius.circular(8),
  border: Border.all(
    color: isDarkMode
        ? const Color(0xFF48484A).withValues(alpha: 0.6)
        : const Color(0xFFDCDCE0),
    width: 0.8,
  ),
);

/// Bölüm başlığı etiketi ("Çoğul", "Mazi", "Örnek Cümleler"...).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: _blue,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// Kökü ekranda temiz göstermek için: harekeleri/uzatma çizgisini siler ve
/// Farsça klavyeden gelen ی ve ک harflerini Arapça karşılıklarına çevirir
/// (ی son harfte noktasız çizildiği için kökte yanlış "nokta" farkı oluşuyordu).
String cleanRoot(String? root) {
  if (root == null) return '';
  return root
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640\u0653-\u0655.,;:·•]'), '')
      .replaceAll('\u06CC', '\u064A')
      .replaceAll('\u06A9', '\u0643')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Kartın başlık satırı: harekeli kelime, hemen yanında kelimeden biraz
/// küçük ve soluk renkte kökü (etiket/kutu olmadan), ardından kelime türü.
class WordHeadline extends StatelessWidget {
  const WordHeadline({
    super.key,
    required this.word,
    required this.isDarkMode,
    this.rightToLeft = false,
  });

  final WordModel word;
  final bool isDarkMode;

  /// Arapça arayüzde kelime sağa yaslanır, kök kelimenin soluna gelir.
  final bool rightToLeft;

  @override
  Widget build(BuildContext context) {
    final wordColor = _primaryText(isDarkMode);
    final title = word.harekeliKelime?.isNotEmpty == true
        ? word.harekeliKelime!
        : word.kelime;
    final root = cleanRoot(word.koku);
    final typeChip = _buildTypeChip();

    final titleWidget = Flexible(
      flex: 3,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: ArabicTextStyles.word.copyWith(color: wordColor),
          textDirection: TextDirection.rtl,
          softWrap: false,
        ),
      ),
    );

    final rootWidget = root.isEmpty
        ? null
        : Flexible(
            flex: 2,
            child: Semantics(
              label: 'kök $root',
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: rightToLeft
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  root,
                  key: const ValueKey('word-root'),
                  style: ArabicTextStyles.root.copyWith(
                    // Opak renk: yarı saydam renkte fontun üst üste binen
                    // hatları koyu "nokta"lar gibi görünüyordu.
                    color: isDarkMode
                        ? const Color(0xFF8A8A8F)
                        : const Color(0xFF9A9AA0),
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          );

    final children = rightToLeft
        ? <Widget>[
            if (typeChip != null) ...[
              typeChip,
              const SizedBox(width: 8),
            ],
            if (rootWidget != null) ...[rootWidget, const SizedBox(width: 6)],
            titleWidget,
          ]
        : <Widget>[
            titleWidget,
            if (rootWidget != null) ...[const SizedBox(width: 6), rootWidget],
            if (typeChip != null) ...[
              const SizedBox(width: 8),
              typeChip,
            ],
          ];

    // Kelime, kök ve tür aynı taban çizgisine oturur (farklı punto boyutlarında
    // ortalamak kökü yukarıda gösteriyordu).
    return Row(
      mainAxisAlignment: rightToLeft
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: children,
    );
  }

  /// Kelime türü etiketi (yalnızca Türkçe arayüzde).
  Widget? _buildTypeChip() {
    if (!LanguageService().isTurkish) return null;

    String? typeText;
    if (word.dilbilgiselOzellikler?.containsKey('tur') == true) {
      typeText = word.dilbilgiselOzellikler!['tur']?.toString();
    } else if (word.tip?.isNotEmpty == true) {
      typeText = word.tip;
    }
    if (typeText == null || typeText.trim().isEmpty) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        typeText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? const Color(0xFF4DA3FF) : _blue,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Türkçe anlam satırı. Arama sorgusu Türkçe karakterden bağımsız
/// vurgulanır ("guzel" araması "güzel"i vurgular); varsa harfi cerler
/// mavi olarak satır içinde devam eder.
class MeaningText extends StatelessWidget {
  const MeaningText({
    super.key,
    required this.word,
    required this.isDarkMode,
    required this.expanded,
    this.searchQuery,
  });

  final WordModel word;
  final bool isDarkMode;
  final bool expanded;
  final String? searchQuery;

  static const _fontSize = 14.5;

  @override
  Widget build(BuildContext context) {
    final textColor = _secondaryText(isDarkMode);
    final baseStyle = TextStyle(
      fontSize: _fontSize,
      color: textColor,
      height: 1.35,
      fontWeight: FontWeight.w400,
    );
    final highlightStyle = baseStyle.copyWith(
      color: _primaryText(isDarkMode),
      fontWeight: FontWeight.w700,
      backgroundColor: isDarkMode
          ? const Color(0x40007AFF)
          : const Color(0x1A007AFF),
    );
    const harfStyle = TextStyle(
      fontSize: _fontSize,
      color: _blue,
      fontWeight: FontWeight.w700,
      fontFamily: 'ScheherazadeNew',
      height: 1.35,
    );

    final text = word.sadeAnlam ?? '';
    final spans = <InlineSpan>[
      for (final (segment, highlighted) in highlightSegments(text, searchQuery))
        TextSpan(text: segment, style: highlighted ? highlightStyle : baseStyle),
    ];

    // Harfi cerler aynı satırda devam eder (Arapça arayüzde gösterilmez).
    final harfiCerler = word.harfiCerler;
    if (harfiCerler.isNotEmpty && !LanguageService().isArabic) {
      if (!expanded) {
        // Kapalıyken yalnızca harfler, aralarında boşlukla
        final harfs = harfiCerler
            .map((hc) => hc['harf'])
            .where((h) => h != null && h.isNotEmpty)
            .join(' ');
        if (harfs.isNotEmpty) {
          spans.add(
            TextSpan(text: text.isEmpty ? harfs : ' $harfs', style: harfStyle),
          );
        }
      } else {
        // Açıkken harf ve anlamı virgülle ayrılarak akar
        for (var i = 0; i < harfiCerler.length; i++) {
          final harf = harfiCerler[i]['harf'] ?? '';
          final anlam = harfiCerler[i]['anlamlar'] ?? '';
          final prefix = (i == 0 && text.isEmpty) ? '' : ', ';
          if (harf.isNotEmpty) {
            spans.add(TextSpan(text: '$prefix$harf ', style: harfStyle));
          }
          if (anlam.isNotEmpty) {
            spans.add(TextSpan(text: anlam, style: baseStyle));
          }
        }
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: expanded ? null : 3,
      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }
}

/// [text]'i, [query]'nin geçtiği yerler vurgulanacak şekilde parçalara
/// böler. Karşılaştırma büyük/küçük harf ve Türkçe karakterden bağımsızdır.
List<(String, bool)> highlightSegments(String text, String? query) {
  final q = query?.trim() ?? '';
  if (q.isEmpty || text.isEmpty) return [(text, false)];

  String fold(String s) => s.split('').map(foldTurkishChar).join();
  final foldedText = fold(text);
  final foldedQuery = fold(q);

  final segments = <(String, bool)>[];
  var start = 0;
  while (start < text.length) {
    final index = foldedText.indexOf(foldedQuery, start);
    if (index == -1) {
      segments.add((text.substring(start), false));
      break;
    }
    if (index > start) segments.add((text.substring(start, index), false));
    segments.add((text.substring(index, index + foldedQuery.length), true));
    start = index + foldedQuery.length;
  }
  return segments;
}

/// Çoğul formu kutusu.
class PluralBox extends StatelessWidget {
  const PluralBox({super.key, required this.word, required this.isDarkMode});

  final WordModel word;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final plural =
        word.dilbilgiselOzellikler?['cogulForm']?.toString().trim() ?? '';
    if (plural.isEmpty) return const SizedBox.shrink();

    final label = LanguageService().isEnglish
        ? 'Plural'
        : (LanguageService().isArabic ? 'جمع' : 'Çoğul');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: _sectionDecoration(isDarkMode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label),
            const SizedBox(height: 2),
            Center(
              child: Text(
                plural,
                style: ArabicTextStyles.form.copyWith(
                  fontSize: 18,
                  color: _primaryText(isDarkMode),
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mazi, müzari, mastar ve emir formları yan yana.
class ConjugationRow extends StatelessWidget {
  const ConjugationRow({super.key, required this.word, required this.isDarkMode});

  final WordModel word;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final cekimler = word.fiilCekimler;
    if (cekimler == null || cekimler.isEmpty) return const SizedBox.shrink();

    final lang = LanguageService();
    String label(String en, String ar, String tr) =>
        lang.isEnglish ? en : (lang.isArabic ? ar : tr);
    final forms = <(String, String)>[
      for (final (key, en, ar, tr) in const [
        ('maziForm', 'Past', 'ماضي', 'Mazi'),
        ('muzariForm', 'Present', 'مضارع', 'Müzari'),
        ('mastarForm', 'Infinitive', 'مصدر', 'Mastar'),
        ('emirForm', 'Imperative', 'أمر', 'Emir'),
      ])
        if (cekimler[key]?.toString().trim().isNotEmpty == true)
          (label(en, ar, tr), cekimler[key].toString()),
    ];
    if (forms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Directionality(
        textDirection: lang.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          children: [
            for (var i = 0; i < forms.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _buildForm(forms[i].$1, forms[i].$2)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm(String title, String form) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
      decoration: _sectionDecoration(isDarkMode),
      child: Column(
        children: [
          _SectionLabel(title),
          Expanded(
            child: Center(
              // Uzun formlar "…" ile kesilmek yerine sığacak kadar küçülür.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  form,
                  style: ArabicTextStyles.form.copyWith(
                    color: _primaryText(isDarkMode),
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Örnek cümleler (en fazla iki). Arapça cümle sağa yaslı ve tamamı
/// görünür; altında Türkçe çevirisi.
class ExampleSentences extends StatelessWidget {
  const ExampleSentences({
    super.key,
    required this.word,
    required this.isDarkMode,
  });

  final WordModel word;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final examples = word.ornekCumleler?.take(2).toList() ?? const [];
    if (examples.isEmpty) return const SizedBox.shrink();

    final divider = Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: isDarkMode
          ? const Color(0xFF48484A).withValues(alpha: 0.5)
          : const Color(0xFFE3E3E8),
    );

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: _sectionDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(
            LanguageService().isEnglish ? 'Example Sentences' : 'Örnek Cümleler',
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < examples.length; i++) ...[
            if (i > 0) divider,
            ..._buildExample(examples[i]),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildExample(Map<String, dynamic> example) {
    final arabic =
        (example['arapcaCumle'] ?? example['arapcaCümle'] ?? example['arapca'])
            ?.toString();
    final turkish =
        example['turkceAnlam']?.toString() ??
        example['turkceCeviri']?.toString() ??
        example['turkce']?.toString() ??
        example.toString();

    return [
      if (arabic != null && arabic.isNotEmpty) ...[
        Text(
          arabic,
          style: ArabicTextStyles.example.copyWith(
            color: isDarkMode
                ? const Color(0xFFE5E5EA)
                : const Color(0xFF1C1C1E),
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 2),
      ],
      Text(
        turkish,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: _secondaryText(isDarkMode),
          height: 1.4,
          letterSpacing: 0.1,
        ),
      ),
    ];
  }
}

/// Genişleyen kartın altındaki AI asistanı satırı: iki küçük, yumuşak
/// mavi hap. Büyük dolu butonlar yerine kartın dilini taşır.
class AiAssistPills extends StatelessWidget {
  const AiAssistPills({
    super.key,
    required this.isDarkMode,
    required this.onAsk,
    required this.onMoreExamples,
    this.showMoreExamples = true,
  });

  final bool isDarkMode;
  final VoidCallback onAsk;
  final VoidCallback onMoreExamples;
  final bool showMoreExamples;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    final ask = lang.isEnglish
        ? 'Ask assistant'
        : (lang.isArabic ? 'اسأل المساعد' : 'Asistana sor');
    final more = lang.isEnglish ? 'More examples' : 'Daha fazla örnek';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _pill(ask, onAsk),
        if (showMoreExamples) _pill(more, onMoreExamples),
      ],
    );
  }

  Widget _pill(String label, VoidCallback onTap) {
    return Material(
      color: _blue.withValues(alpha: isDarkMode ? 0.16 : 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: _blue),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? const Color(0xFF4DA3FF) : _blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
