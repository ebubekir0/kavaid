import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';

/// Emsile (Fiil Çekimleri) Bottom Sheet Widget
/// Arapça fiillerin tüm şahıslara göre mazi, müzari ve emir çekimlerini gösterir.
class EmsileBottomSheet extends StatefulWidget {
  final WordModel word;
  final bool isDarkMode;

  const EmsileBottomSheet({
    super.key,
    required this.word,
    required this.isDarkMode,
  });

  /// Bottom sheet'i göstermek için kolaylık metodu
  static Future<void> show(BuildContext context, WordModel word) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmsileBottomSheet(word: word, isDarkMode: isDarkMode),
    );
  }

  @override
  State<EmsileBottomSheet> createState() => _EmsileBottomSheetState();
}

class _EmsileBottomSheetState extends State<EmsileBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Renk paleti
  static const _accentBlue = Color(0xFF007AFF);
  static const _maziColor = Color(0xFF34C759);    // Yeşil
  static const _muzariColor = Color(0xFF5856D6);   // Mor
  static const _emirColor = Color(0xFFFF9500);     // Turuncu

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// fiilCekimler'dan veya emsile alt alanından çekim verilerini al
  Map<String, dynamic>? get _emsileData {
    final fc = widget.word.fiilCekimler;
    if (fc == null) return null;
    // Yeni genişletilmiş format: emsile alt alanı var mı?
    if (fc.containsKey('emsile') && fc['emsile'] is Map) {
      return Map<String, dynamic>.from(fc['emsile'] as Map);
    }
    return null;
  }

  /// Mevcut basit çekimlerden (maziForm, muzariForm) sadece bilinen formları göster (fallback)
  Map<String, Map<String, String>> _generateFallbackEmsile() {
    final fc = widget.word.fiilCekimler;
    final maziBase = fc?['maziForm']?.toString() ?? '';
    final muzariBase = fc?['muzariForm']?.toString() ?? '';
    final emirBase = fc?['emirForm']?.toString() ?? '';

    // Fallback modunda sadece temel هُوَ / أَنْتَ formlarını göster
    // Arapça harflerle substring yapmak doğru sonuç vermeyeceğinden
    // tahmini çekim üretmiyoruz
    return {
      'mazi': {
        if (maziBase.isNotEmpty) 'هُوَ': maziBase,
      },
      'muzari': {
        if (muzariBase.isNotEmpty) 'هُوَ': muzariBase,
      },
      'emir': {
        if (emirBase.isNotEmpty) 'أَنْتَ': emirBase,
      },
    };
  }

  /// Emsile verisini çözümle
  Map<String, List<MapEntry<String, String>>> _getConjugationData() {
    final emsile = _emsileData;
    
    if (emsile != null) {
      // Yeni genişletilmiş formattan oku
      return {
        'mazi': _parseSection(emsile['mazi']),
        'muzari': _parseSection(emsile['muzari']),
        'emir': _parseSection(emsile['emir']),
      };
    }

    // Fallback: mevcut basit çekimlerden tahmini tablo
    final fallback = _generateFallbackEmsile();
    return {
      'mazi': fallback['mazi']!.entries
          .where((e) => e.value.isNotEmpty)
          .toList(),
      'muzari': fallback['muzari']!.entries
          .where((e) => e.value.isNotEmpty)
          .toList(),
      'emir': fallback['emir']!.entries
          .where((e) => e.value.isNotEmpty)
          .toList(),
    };
  }

  List<MapEntry<String, String>> _parseSection(dynamic section) {
    if (section == null) return [];
    if (section is Map) {
      return section.entries
          .map((e) => MapEntry(e.key.toString(), e.value.toString()))
          .where((e) => e.value.isNotEmpty)
          .toList();
    }
    return [];
  }

  // Zamir'in Türkçe karşılığı
  static const _zamirTurkce = {
    'هُوَ': 'O (eril)',
    'هِيَ': 'O (dişil)',
    'هُمَا': 'İkisi',
    'هُمَا_م': 'İkisi (eril)',
    'هُمَا_ف': 'İkisi (dişil)',
    'هُمْ': 'Onlar (eril)',
    'هُنَّ': 'Onlar (dişil)',
    'أَنْتَ': 'Sen (eril)',
    'أَنْتِ': 'Sen (dişil)',
    'أَنْتُمَا': 'İkiniz',
    'أَنْتُمْ': 'Siz (eril)',
    'أَنْتُنَّ': 'Siz (dişil)',
    'أَنَا': 'Ben',
    'نَحْنُ': 'Biz',
  };

  // Şahıs grupları
  static const _groupLabels = {
    0: 'غَائِب (3. Şahıs)',
    7: 'مُخَاطَب (2. Şahıs)',
    12: 'مُتَكَلِّم (1. Şahıs)',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final data = _getConjugationData();
    final mastarForm = widget.word.fiilCekimler?['mastarForm']?.toString() ?? '';
    final harekeli = widget.word.harekeliKelime ?? widget.word.kelime;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Başlık alanı
          _buildHeader(isDark, harekeli, mastarForm),

          // Tab bar
          _buildTabBar(isDark),

          // Tab içerikleri
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConjugationTable(data['mazi'] ?? [], isDark, _maziColor, 'Mazi'),
                _buildConjugationTable(data['muzari'] ?? [], isDark, _muzariColor, 'Müzari'),
                _buildConjugationTable(data['emir'] ?? [], isDark, _emirColor, 'Emir'),
              ],
            ),
          ),

          // Alt bilgi
          _buildFooterInfo(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, String harekeli, String mastarForm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Sol: Başlık
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'اَلْأَمْثِلَة',
                        style: GoogleFonts.scheherazadeNew(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Emsile Çekimleri',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (widget.word.anlam?.isNotEmpty == true)
                  Text(
                    widget.word.anlam!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Sağ: Arapça fiil
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2C2E), const Color(0xFF3A3A3C)]
                    : [const Color(0xFFF2F2F7), const Color(0xFFE5E5EA)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD1D1D6),
                width: 0.5,
              ),
            ),
            child: Text(
              harekeli,
              style: GoogleFonts.scheherazadeNew(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                height: 1.3,
                fontFeatures: const [
                  ui.FontFeature.enable('liga'),
                  ui.FontFeature.enable('calt'),
                ],
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [_accentBlue, _accentBlue.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: _accentBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? const Color(0xFF8E8E93)
            : const Color(0xFF6D6D70),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(3),
        tabs: const [
          Tab(text: 'Mazi (Geçmiş)'),
          Tab(text: 'Müzari (Geniş)'),
          Tab(text: 'Emir'),
        ],
      ),
    );
  }

  Widget _buildConjugationTable(
    List<MapEntry<String, String>> entries,
    bool isDark,
    Color accentColor,
    String tabTitle,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: isDark
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD1D1D6),
              ),
              const SizedBox(height: 12),
              Text(
                '$tabTitle çekimi bulunamadı',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final zamir = entry.key;
        final cekim = entry.value;
        final turkce = _zamirTurkce[zamir] ?? '';

        // Grup başlığı kontrolü
        Widget? groupHeader;
        if (_groupLabels.containsKey(index)) {
          groupHeader = _buildGroupHeader(
            _groupLabels[index]!,
            isDark,
            accentColor,
          );
        }

        return Column(
          children: [
            if (groupHeader != null) groupHeader,
            _buildConjugationRow(
              zamir: zamir,
              cekim: cekim,
              turkce: turkce,
              isDark: isDark,
              accentColor: accentColor,
              isEven: index.isEven,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupHeader(String label, bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 0.5,
              color: accentColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConjugationRow({
    required String zamir,
    required String cekim,
    required String turkce,
    required bool isDark,
    required Color accentColor,
    required bool isEven,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEven
            ? (isDark
                ? const Color(0xFF2C2C2E).withOpacity(0.5)
                : const Color(0xFFF8F9FA))
            : (isDark
                ? const Color(0xFF1C1C1E)
                : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF38383A).withOpacity(0.5)
              : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Sol: Türkçe karşılık
          SizedBox(
            width: 90,
            child: Text(
              turkce,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF8E8E93),
              ),
            ),
          ),

          // Orta: Zamir (Arapça)
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              zamir.replaceAll('_م', '').replaceAll('_ف', ''),
              style: GoogleFonts.scheherazadeNew(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accentColor,
                height: 1.4,
                fontFeatures: const [
                  ui.FontFeature.enable('liga'),
                  ui.FontFeature.enable('calt'),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Sağ: Çekim formu (Arapça)
          Expanded(
            child: Text(
              cekim,
              style: GoogleFonts.scheherazadeNew(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                height: 1.4,
                fontFeatures: const [
                  ui.FontFeature.enable('liga'),
                  ui.FontFeature.enable('calt'),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(bool isDark) {
    final koku = widget.word.koku ?? '';
    final ismiFail = _emsileData?['ismiFail']?.toString() ?? '';
    final ismiMeful = _emsileData?['ismiMeful']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2E).withOpacity(0.5)
            : const Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF38383A)
                : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (koku.isNotEmpty)
              _buildFooterChip('Kök', koku, isDark, const Color(0xFF007AFF)),
            if (koku.isNotEmpty && (ismiFail.isNotEmpty || ismiMeful.isNotEmpty))
              const SizedBox(width: 8),
            if (ismiFail.isNotEmpty)
              _buildFooterChip(
                  'İsm-i Fail', ismiFail, isDark, const Color(0xFF34C759)),
            if (ismiFail.isNotEmpty && ismiMeful.isNotEmpty)
              const SizedBox(width: 8),
            if (ismiMeful.isNotEmpty)
              _buildFooterChip(
                  'İsm-i Mef\'ul', ismiMeful, isDark, const Color(0xFFFF9500)),
            if (koku.isEmpty && ismiFail.isEmpty && ismiMeful.isEmpty)
              Text(
                'Fiil çekimleri • Kavaid Sözlük',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF48484A)
                      : const Color(0xFFC7C7CC),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterChip(
      String label, String value, bool isDark, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.scheherazadeNew(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                height: 1.3,
                fontFeatures: const [
                  ui.FontFeature.enable('liga'),
                  ui.FontFeature.enable('calt'),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
