// Sözlük kartının (SearchResultCard) görsel parçaları. Servis bağımlılığı
// yoktur; yalnızca kelime verisinden çizim yapar, bu yüzden testte tek
// başına çizilebilir.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/word_model.dart';
import '../services/language_service.dart';
import '../services/search_ranking.dart' show foldTurkishChar;
import '../utils/arabic_text.dart';

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

  /// Kelimenin yanındaki kök: kelimeden azıcık küçük, soluk renkte.
  static const root = TextStyle(
    fontFamily: 'ScheherazadeNew',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFeatures: _arabicFeatures,
  );

  /// Örnek cümle. Arap yazısı Latin metinden küçük görünür; bu yüzden Türkçe
  /// çevirisinden (14 pt) belirgin şekilde büyük tutulur.
  static const example = TextStyle(
    fontFamily: 'ScheherazadeNew',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.55,
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

/// Kartın başlık satırı: harekeli kelime, hemen yanında kelimeden azıcık küçük
/// ve soluk renkte kökü (etiket/kutu olmadan), ardından kelime türü.
///
/// Kelime ve kök kendi boyutunda yan yana durur; yer yoksa birlikte küçülürler.
/// Tür etiketi onların yanına sığıyorsa yanında, sığmıyorsa ("İsim Tamlaması"
/// gibi uzun etiketler dar telefonda) alt satırda durur; hiçbir zaman
/// küçülmez ya da kesilmez. (Eskiden her parça sabit oranda yer alıyor ve ayrı
/// ayrı küçülüyordu: dar telefonlarda kök kartlara göre farklı boyutta
/// çiziliyor, tür etiketi "Mazî F…" diye kesiliyordu.)
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
    final root = formatRoot(word.koku);
    final type = _typeLabel();

    final titleAndRoot = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: rightToLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: rightToLeft ? TextDirection.rtl : TextDirection.ltr,
        // Farklı punto boyutlarındaki kelime ve kök aynı taban çizgisine oturur.
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: ArabicTextStyles.word.copyWith(color: wordColor),
            textDirection: TextDirection.rtl,
            softWrap: false,
          ),
          if (root.isNotEmpty) ...[
            const SizedBox(width: 8),
            Semantics(
              label: 'kök $root',
              child: Text(
                root,
                key: const ValueKey('word-root'),
                style: ArabicTextStyles.root.copyWith(
                  color: wordColor.withValues(alpha: isDarkMode ? 0.55 : 0.5),
                ),
                textDirection: TextDirection.rtl,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ],
      ),
    );

    return Wrap(
      textDirection: rightToLeft ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 2,
      children: [
        titleAndRoot,
        if (type != null) _TypeChip(label: type, isDarkMode: isDarkMode),
      ],
    );
  }

  /// Kelime türü (yalnızca Türkçe arayüzde gösterilir).
  String? _typeLabel() {
    if (!LanguageService().isTurkish) return null;

    String? type;
    if (word.dilbilgiselOzellikler?.containsKey('tur') == true) {
      type = word.dilbilgiselOzellikler!['tur']?.toString();
    } else if (word.tip?.isNotEmpty == true) {
      type = word.tip;
    }
    final trimmed = type?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Kelime türü etiketi ("İsim", "Mazî Fiil"...).
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.isDarkMode});

  final String label;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
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

    // Text.rich: RichText'in aksine sistem yazı boyutu ayarını uygular ve
    // temadan font ailesini alır.
    return Text.rich(
      TextSpan(children: spans),
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

/// Örnek cümleler (en fazla iki). Arapça cümle sağdan sola, tamamı görünür ve
/// sağa yaslıdır; Türkçe çevirisi de aynı kenara yaslanır, böylece çift tek
/// parça gibi okunur. Sağ kenardaki ince çizgi her cümle çiftini ayırır.
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
      decoration: _sectionDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(
            LanguageService().isEnglish ? 'Example Sentences' : 'Örnek Cümleler',
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < examples.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _ExamplePair(example: examples[i], isDarkMode: isDarkMode),
          ],
        ],
      ),
    );
  }
}

class _ExamplePair extends StatelessWidget {
  const _ExamplePair({required this.example, required this.isDarkMode});

  final Map<String, dynamic> example;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final arabic =
        (example['arapcaCumle'] ?? example['arapcaCümle'] ?? example['arapca'])
            ?.toString()
            .trim() ??
        '';
    final turkish =
        example['turkceAnlam']?.toString() ??
        example['turkceCeviri']?.toString() ??
        example['turkce']?.toString() ??
        example.toString();

    return Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: _blue.withValues(alpha: isDarkMode ? 0.65 : 0.45),
            width: 2.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (arabic.isNotEmpty) ...[
            Text(
              arabic,
              style: ArabicTextStyles.example.copyWith(
                color: isDarkMode
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFF1C1C1E),
              ),
              // start + rtl = sağa yaslı
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 3),
          ],
          // Türkçe çeviri soldan sağa okunur ama Arapça cümleyle aynı kenara
          // (sağa) yaslanır.
          Text(
            turkish,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _secondaryText(isDarkMode),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kart başlığındaki ikon butonu: 32×32 dokunma alanı, 21 px simge. Tüm
/// butonlar aynı (rounded) ikon ailesinden ve aynı boyutta olsun diye ortak.
class CardIconButton extends StatelessWidget {
  const CardIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDarkMode,
    this.color,
    this.turns = 0,
  });

  final IconData icon;

  /// Ekran okuyucu için buton adı.
  final String label;
  final VoidCallback? onTap;
  final bool isDarkMode;

  /// Verilmezse ikincil metin rengi kullanılır (ör. kayıtlıyken mavi).
  final Color? color;

  /// Simgenin dönüş miktarı (genişleme oku için, 0.5 = yarım tur).
  final double turns;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AnimatedRotation(
                turns: turns,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 21,
                  color: color ?? _secondaryText(isDarkMode),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yapay zekâ asistanının görsel kimliği: mavi tonlu yuvarlatılmış kare içinde
/// parıltı simgesi. Sohbet ekranının başlığında ve mesaj avatarında da aynı
/// işaret kullanılır; kartta da aynısı olsun diye ortak.
class AiMark extends StatelessWidget {
  const AiMark({super.key, required this.isDarkMode, this.size = 28});

  final bool isDarkMode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: isDarkMode ? 0.22 : 0.11),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.58,
        color: isDarkMode ? const Color(0xFF4DA3FF) : _blue,
      ),
    );
  }
}

/// Kart başlığındaki "Asistana sor" butonu. Diğer ikonlar gibi 32×32 dokunma
/// alanına sahiptir, ama yalnızca bu buton tonlu zemin taşır: yapay zekâ
/// girişi olduğu ilk bakışta anlaşılır, yanındaki gri ikonlara da yabancı durmaz.
class AiTileButton extends StatelessWidget {
  const AiTileButton({super.key, required this.onTap, required this.isDarkMode});

  final VoidCallback onTap;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Asistana sor',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(child: AiMark(isDarkMode: isDarkMode, size: 26)),
          ),
        ),
      ),
    );
  }
}

/// Genişleyen kartın en altındaki tek yapay zekâ alanı: asistanın kimliği,
/// serbest soru girişi ve üç hazır soru. (Eskiden kartın üstünde ve örnek
/// cümlelerin içinde iki ayrı tam genişlikte mavi buton vardı; kartın geri
/// kalanıyla uyumsuz, "sonradan eklenmiş" görünüyorlardı.)
class AiAssistStrip extends StatelessWidget {
  const AiAssistStrip({
    super.key,
    required this.word,
    required this.isDarkMode,
    required this.onAsk,
  });

  final WordModel word;
  final bool isDarkMode;

  /// [message] null ise boş sohbet açılır, doluysa o soruyla başlar.
  final void Function(String? message) onAsk;

  /// Hazır sorular: (etiket, asistana giden mesaj). İki tane olması bilinçli:
  /// 360 px genişlikte tek satıra sığar; "nasıl kullanılır" gibi diğer sorular
  /// zaten üstteki serbest soru satırından sorulabilir.
  static const prompts = <(String, String)>[
    (
      'Daha fazla örnek',
      'Bu kelimeyle seviyeme uygun 5 yeni örnek ver: kolaydan zora doğru.',
    ),
    (
      'Benzer kelimeler',
      'Bu kelimeye benzeyen kelimeler neler ve aralarındaki fark nedir? Kısaca anlat.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final head = (word.harekeliKelime?.isNotEmpty == true
            ? word.harekeliKelime!
            : word.kelime)
        .trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: _sectionDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onAsk(null),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                AiMark(isDarkMode: isDarkMode),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistana sor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primaryText(isDarkMode),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: head,
                              // Arapça kısım Latin metnin yedek fontuna düşmesin
                              style: const TextStyle(
                                fontFamily: 'ScheherazadeNew',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' hakkında soru sor'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _secondaryText(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _secondaryText(isDarkMode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, message) in prompts)
                _PromptChip(
                  label: label,
                  isDarkMode: isDarkMode,
                  onTap: () => onAsk(message),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.label,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? const Color(0xFF4DA3FF) : _blue;
    return Material(
      color: _blue.withValues(alpha: isDarkMode ? 0.14 : 0.06),
      shape: StadiumBorder(
        side: BorderSide(
          color: _blue.withValues(alpha: isDarkMode ? 0.4 : 0.28),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
