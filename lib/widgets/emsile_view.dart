import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

/// Emsile Ekran\u0131
/// - Kapal\u0131 sat\u0131r: RTL  [G\u0130TMEK ............. \u0630\u064e\u0647\u064e\u0628\u064e  \u064a\u064e\u0630\u0652\u0647\u064e\u0628\u0640\u064f  \u203a]
/// - A\u00e7\u0131k detay  : kompakt anlam + 24 s\u0131\u011fa (3 s\u00fctun RTL)
///   S\u0131\u011fa 1/2/13 kartlar\u0131n\u0131n alt\u0131nda mavi \"\u00e7ekim\" butonu \u2192 o sat\u0131r\u0131n alt\u0131na a\u00e7\u0131l\u0131r
class EmsileView extends StatefulWidget {
  final bool isDarkMode;
  final List<Map<String, dynamic>>? verbs;
  final double bottomPadding;
  final bool isPremium;
  final VoidCallback? onPremiumTap;
  final VoidCallback? onLoadMore;
  final VoidCallback? onLoadFreeTap;
  final bool hasMore;
  final bool isSearchMode;

  const EmsileView({
    super.key,
    required this.isDarkMode,
    this.verbs,
    this.bottomPadding = 0,
    this.isPremium = false,
    this.onPremiumTap,
    this.onLoadMore,
    this.onLoadFreeTap,
    this.hasMore = false,
    this.isSearchMode = false,
  });

  @override
  State<EmsileView> createState() => _EmsileViewState();
}

final Set<int> _globalExpandedIds = {};
final Map<int, String?> _globalOpenIds = {};

class _EmsileViewState extends State<EmsileView> {
  Set<int> get _expandedIds => _globalExpandedIds;

  Map<int, String?> get _openConj => _globalOpenIds;

  // Sabit 300 \u00fccretsiz kart ID limiti
  static const int _freeCardLimit = 300;

  // siga listesinde hangi index hangi çekimi açar
  static const Map<int, String> _sigaToConj = {
    0:  'mazi',   // sira 1 → Fiil-i Mâzi
    1:  'muzari', // sira 2 → Fiil-i Muzâri
  };

  // hangi çekim hangi satırda (0-based satır index)
  static const Map<String, int> _conjToRow = {
    'mazi':   0,
    'muzari': 0,
  };

  // \u2500\u2500 S\u0131\u011fa Kartlar\u0131 Temalar\u0131 (Debug) \u2500\u2500
  static const List<Map<String, Color>> _appThemes = [
    {'bg': Color(0xFFF0F4FB), 'rowBg': Color(0xFFFFFFFF), 'detailBg': Color(0xFFE8EFF9), 'div': Color(0xFFD0DCF0), 'sigaBg': Color(0xFFDCE8F8), 'sigaBrd': Color(0xFFAFC6E5), 'conjBg': Color(0xFFDEECFB), 'cellBg': Color(0xFFD0E4F7), 'arabic': Color(0xFF0A2342), 'anlam': Color(0xFF3D5C80), 'label': Color(0xFF2952A3), 'accent': Color(0xFF1558D6), 'btnBg': Color(0xFFBFD7FA)},
    {'bg': Color(0xFFE7EAF6), 'rowBg': Color(0xFFF5F6FA), 'detailBg': Color(0xFFD6DCEE), 'div': Color(0xFFC0C8E3), 'sigaBg': Color(0xFFCCD4EB), 'sigaBrd': Color(0xFFA2AED6), 'conjBg': Color(0xFFC9D0E8), 'cellBg': Color(0xFFBCC5E0), 'arabic': Color(0xFF1A1F36), 'anlam': Color(0xFF4A5578), 'label': Color(0xFF333D60), 'accent': Color(0xFF2B418E), 'btnBg': Color(0xFFA9B5E0)},
    {'bg': Color(0xFFF4F8FA), 'rowBg': Color(0xFFFFFFFF), 'detailBg': Color(0xFFE9F1F6), 'div': Color(0xFFD3E2EE), 'sigaBg': Color(0xFFE0ECF4), 'sigaBrd': Color(0xFFB5D1EA), 'conjBg': Color(0xFFDCEBF4), 'cellBg': Color(0xFFCFE3EF), 'arabic': Color(0xFF132A3B), 'anlam': Color(0xFF476478), 'label': Color(0xFF2C506C), 'accent': Color(0xFF196A9E), 'btnBg': Color(0xFFB9DAEF)},
    {'bg': Color(0xFFEDF0F2), 'rowBg': Color(0xFFF7F9FA), 'detailBg': Color(0xFFE2E7EB), 'div': Color(0xFFCBD3D9), 'sigaBg': Color(0xFFD6DEE3), 'sigaBrd': Color(0xFFB4C0C8), 'conjBg': Color(0xFFD5DDE2), 'cellBg': Color(0xFFC8D3D9), 'arabic': Color(0xFF212C33), 'anlam': Color(0xFF556066), 'label': Color(0xFF3B4A53), 'accent': Color(0xFF4A7B9D), 'btnBg': Color(0xFFB0C9D9)},
    {'bg': Color(0xFFEBEFF2), 'rowBg': Color(0xFFFFFFFF), 'detailBg': Color(0xFFE0E6EB), 'div': Color(0xFFC8D2D9), 'sigaBg': Color(0xFFD4DEE5), 'sigaBrd': Color(0xFFAAB8C4), 'conjBg': Color(0xFFD1DCE3), 'cellBg': Color(0xFFC3D1DA), 'arabic': Color(0xFF1F2B33), 'anlam': Color(0xFF4B5B66), 'label': Color(0xFF324350), 'accent': Color(0xFF3C617B), 'btnBg': Color(0xFFA6C2D6)},
    {'bg': Color(0xFFEFEFF7), 'rowBg': Color(0xFFF8F8FB), 'detailBg': Color(0xFFE2E2F2), 'div': Color(0xFFCACAE3), 'sigaBg': Color(0xFFD9D9EC), 'sigaBrd': Color(0xFFB3B3D6), 'conjBg': Color(0xFFD6D6EA), 'cellBg': Color(0xFFCACAE3), 'arabic': Color(0xFF1F1F3D), 'anlam': Color(0xFF50507A), 'label': Color(0xFF3B3B66), 'accent': Color(0xFF4646B5), 'btnBg': Color(0xFFB2B2DE)},
    {'bg': Color(0xFFEAF4F6), 'rowBg': Color(0xFFF4F9FA), 'detailBg': Color(0xFFDAECEE), 'div': Color(0xFFBFDEDF), 'sigaBg': Color(0xFFCDE6E8), 'sigaBrd': Color(0xFFA1D0D3), 'conjBg': Color(0xFFCAE4E7), 'cellBg': Color(0xFFBBDADF), 'arabic': Color(0xFF143033), 'anlam': Color(0xFF43696C), 'label': Color(0xFF285458), 'accent': Color(0xFF208A93), 'btnBg': Color(0xFF9DD8DA)},
    {'bg': Color(0xFFE9EDF5), 'rowBg': Color(0xFFFFFFFF), 'detailBg': Color(0xFFDAE1F0), 'div': Color(0xFFBEC9E4), 'sigaBg': Color(0xFFCBD6ED), 'sigaBrd': Color(0xFF9EAFD9), 'conjBg': Color(0xFFC6D2EC), 'cellBg': Color(0xFFBAC9E8), 'arabic': Color(0xFF121E38), 'anlam': Color(0xFF425170), 'label': Color(0xFF25375A), 'accent': Color(0xFF1C45A3), 'btnBg': Color(0xFFA2B9EA)},
    {'bg': Color(0xFFEAEBF2), 'rowBg': Color(0xFFF4F5F8), 'detailBg': Color(0xFFD8DBE9), 'div': Color(0xFFBBC0D9), 'sigaBg': Color(0xFFC8CCDF), 'sigaBrd': Color(0xFF9EA6C8), 'conjBg': Color(0xFFC3C7DC), 'cellBg': Color(0xFFB7BBD3), 'arabic': Color(0xFF111428), 'anlam': Color(0xFF3C4362), 'label': Color(0xFF252A4A), 'accent': Color(0xFF29378C), 'btnBg': Color(0xFF9FA8D3)},
    {'bg': Color(0xFFEBF6F5), 'rowBg': Color(0xFFF5FAFA), 'detailBg': Color(0xFFD9EFEB), 'div': Color(0xFFC0E3DD), 'sigaBg': Color(0xFFCDECE6), 'sigaBrd': Color(0xFFA2D7CD), 'conjBg': Color(0xFFC7EAE5), 'cellBg': Color(0xFFBCDFD9), 'arabic': Color(0xFF0F2C27), 'anlam': Color(0xFF3A635B), 'label': Color(0xFF254B44), 'accent': Color(0xFF128975), 'btnBg': Color(0xFF99D6CA)},
    {'bg': Color(0xFFEDF2F6), 'rowBg': Color(0xFFFFFFFF), 'detailBg': Color(0xFFDFE8ED), 'div': Color(0xFFC3D4DF), 'sigaBg': Color(0xFFCDDDE6), 'sigaBrd': Color(0xFFA5C1D2), 'conjBg': Color(0xFFC9D9E3), 'cellBg': Color(0xFFBAD0DB), 'arabic': Color(0xFF182730), 'anlam': Color(0xFF4E6370), 'label': Color(0xFF334A59), 'accent': Color(0xFF296796), 'btnBg': Color(0xFFA8C6DE)},
    {'bg': Color(0xFFF0F1F3), 'rowBg': Color(0xFFFCFCFD), 'detailBg': Color(0xFFDDE1E8), 'div': Color(0xFFC1C8D5), 'sigaBg': Color(0xFFCED3DD), 'sigaBrd': Color(0xFFA9B3C6), 'conjBg': Color(0xFFCCD2DD), 'cellBg': Color(0xFFBEC5D4), 'arabic': Color(0xFF1B1E26), 'anlam': Color(0xFF535866), 'label': Color(0xFF3A4151), 'accent': Color(0xFF4A5A82), 'btnBg': Color(0xFFADB7CD)},
    {'bg': Color(0xFFE8EDF8), 'rowBg': Color(0xFFF5F8FC), 'detailBg': Color(0xFFD6E2F5), 'div': Color(0xFFBACBEA), 'sigaBg': Color(0xFFC7D7F1), 'sigaBrd': Color(0xFF9FBAE2), 'conjBg': Color(0xFFC1D3EF), 'cellBg': Color(0xFFB2C7E9), 'arabic': Color(0xFF0C1935), 'anlam': Color(0xFF384D75), 'label': Color(0xFF1E3562), 'accent': Color(0xFF1C4BC4), 'btnBg': Color(0xFF95B4ED)},
    {'bg': Color(0xFFEFF1FA), 'rowBg': Color(0xFFFFFFFF), 'detailBg': Color(0xFFE0E3F3), 'div': Color(0xFFC5CBE5), 'sigaBg': Color(0xFFD4D8EC), 'sigaBrd': Color(0xFFABADCE), 'conjBg': Color(0xFFCED1E9), 'cellBg': Color(0xFFC0C5E0), 'arabic': Color(0xFF191E3A), 'anlam': Color(0xFF505A80), 'label': Color(0xFF333E6A), 'accent': Color(0xFF3850B3), 'btnBg': Color(0xFFAAB4E0)},
    {'bg': Color(0xFFEAF1F9), 'rowBg': Color(0xFFF8FAFC), 'detailBg': Color(0xFFD9E6F4), 'div': Color(0xFFBFD4EC), 'sigaBg': Color(0xFFCADCF0), 'sigaBrd': Color(0xFFA2C3E5), 'conjBg': Color(0xFFC4D9ED), 'cellBg': Color(0xFFB7CEE5), 'arabic': Color(0xFF0D2138), 'anlam': Color(0xFF3E5A7A), 'label': Color(0xFF224266), 'accent': Color(0xFF135CAE), 'btnBg': Color(0xFF98BFEB)},
  ];

  int _selectedThemeIdx = 12;

  // Holistic Getters
  Color get _bg        => _appThemes[_selectedThemeIdx]['bg']!;
  Color get _rowBg     => _appThemes[_selectedThemeIdx]['rowBg']!;
  Color get _detailBg  => _appThemes[_selectedThemeIdx]['detailBg']!;
  Color get _divColor  => _appThemes[_selectedThemeIdx]['div']!;
  Color get _sigaBg    => _appThemes[_selectedThemeIdx]['sigaBg']!;
  Color get _sigaBrd   => _appThemes[_selectedThemeIdx]['sigaBrd']!;
  Color get _conjRowBg => _appThemes[_selectedThemeIdx]['conjBg']!;
  Color get _cellBg    => _appThemes[_selectedThemeIdx]['cellBg']!;
  Color get _arabicClr => _appThemes[_selectedThemeIdx]['arabic']!;
  Color get _anlamClr  => _appThemes[_selectedThemeIdx]['anlam']!;
  Color get _labelClr  => _appThemes[_selectedThemeIdx]['label']!;
  Color get _accent    => _appThemes[_selectedThemeIdx]['accent']!;
  Color get _btnBg     => _appThemes[_selectedThemeIdx]['btnBg']!;
  Color get _btnOpen   => _appThemes[_selectedThemeIdx]['accent']!;

  // Dynamic Card Colors
  Color get _ccBg      => _sigaBg;
  Color get _ccBorder  => _sigaBrd;
  Color get _ccArrow   => _accent;
  Color get _ccAnlam   => _anlamClr;
  Color get _ccMuzari  => _arabicClr;
  Color get _ccMazi    => _arabicClr;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(EmsileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Arama moduna girildiğinde (yeni bir arama yapıldığında) açık kartları kapat
    if (widget.isSearchMode && !oldWidget.isSearchMode) {
      _expandedIds.clear();
      _openConj.clear();
    }
  }

  bool _isCardLocked(Map<String, dynamic> verb) {
    if (widget.isPremium) return false;
    
    // Premium değilse:
    // Aramada (800 fiil) veya Ana Sayfada (200 fiil) rastgele ama kararlı olarak dağılmış olanlar ücretsiz
    final int freeLimit = widget.isSearchMode ? 800 : 200;
    
    // Deterministic hash: (id * prime) % total_approx < limit
    final id = verb['id'] as int? ?? 9999;
    return ((id * 2654435761) % 7000) >= freeLimit;
  }

  // \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 YARDIMCILAR \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  String _e(Map<String, dynamic> v, int s) {
    final list = v['emsile_24'] as List<dynamic>? ?? [];
    try { return list.firstWhere((e) => e['sira'] == s,
        orElse: () => {'arapca': ''})['arapca'] as String? ?? ''; }
    catch (_) { return ''; }
  }

  List<Map<String, dynamic>> _cekim(Map<String, dynamic> v, String k) {
    final c = v['cekimler'] as Map<String, dynamic>? ?? {};
    return ((c[k] as List<dynamic>?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 B\u0130LG\u0130LEND\u0130RME KARTI \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  Widget _buildInfoCard() {
    final isDarkMode = widget.isDarkMode;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.white.withOpacity(0.03) 
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.08) 
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Text(
            '7000\'den fazla fiilin 24 sığa Emsile-i Muhtelife çekimlerini öğrenin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: isDarkMode ? const Color(0xFFBBBBBB) : const Color(0xFF444446),
            ),
          ),
          if (!widget.isPremium) ...[
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                // Giriş kontrolü
                if (!AuthService().isSignedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Lütfen önce kayıt olun, giriş yapın.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.black87,
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                  return;
                }
                widget.onPremiumTap?.call();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode 
                      ? [const Color(0xFF1E3562), const Color(0xFF141926)]
                      : [const Color(0xFF384D75), const Color(0xFF25375A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'Tüm fiilleri aç',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.7)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 DAHA FAZLA Y\u00dcKLE BUTONU \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onLoadMore,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent.withOpacity(0.15), _accent.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: _accent, size: 18),
                const SizedBox(width: 8),
                Text('Daha Fazla Fiil Y\u00fckle',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _accent)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 BUILD \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  @override
  Widget build(BuildContext context) {
    final verbs = widget.verbs ?? [];

    if (verbs.isEmpty && widget.isSearchMode) {
      return SliverToBoxAdapter(
        child: Container(
          color: _bg,
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: _accent.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'Aranan kelime bulunamad\u0131',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _anlamClr.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Toplam \u00f6\u011fe say\u0131s\u0131: bilgi kart\u0131 + kartlar + (daha fazla butonu)
    final itemCount = 1 + verbs.length + (widget.hasMore && !widget.isSearchMode ? 1 : 0);

    return SliverPadding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding + 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            // 0. index -> Bilgilendirme kart\u0131
            if (i == 0 && !widget.isSearchMode) {
              return _buildInfoCard();
            }
            if (i == 0 && widget.isSearchMode) {
              // Arama modunda bilgi kart\u0131 g\u00f6sterme, direkt ilk sonucu g\u00f6ster
              return _buildRow(verbs[0], 0);
            }
            
            // Son index -> "Daha fazla y\u00fckle" butonu
            final verbIdx = widget.isSearchMode ? i : i - 1;
            if (verbIdx >= verbs.length) {
              return _buildLoadMoreButton();
            }
            
            return _buildRow(verbs[verbIdx], verbIdx);
          },
          childCount: widget.isSearchMode ? verbs.length : itemCount,
        ),
      ),
    );
  }

  // Solda: ok ve anlam, Sa\u011fda: Yekt\u00fcb\u00fc ve Ketebe (en sa\u011fda)
  Widget _buildRow(Map<String, dynamic> verb, int idx) {
    final verbId = verb['id'] as int;
    final locked = _isCardLocked(verb);
    final expanded = !locked && _expandedIds.contains(verbId);
    final anlamlar = verb['anlamlar'] as List<dynamic>? ?? [];
    final anlam    = anlamlar.isNotEmpty ? anlamlar.first.toString().toUpperCase() : '';
    final mazi     = _e(verb, 1);
    final muzari   = _e(verb, 2);

    return Container(
      decoration: BoxDecoration(
        color: locked ? _ccBg.withOpacity(0.6) : _ccBg,
        border: Border(
          bottom: BorderSide(
            color: _ccBorder, 
            width: 1.5
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (locked) {
                // Giriş kontrolü
                if (!AuthService().isSignedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Lütfen önce kayıt olun, giriş yapın.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.black87,
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                  return;
                }
                _showPremiumDialog(context);
                return;
              }
              setState(() {
                if (expanded) {
                  _expandedIds.remove(verbId);
                  _openConj.remove(verbId);
                } else {
                  _expandedIds.add(verbId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  // 1. En Sol: Ok ikonu veya Kilit ikonu
                  locked
                    ? Icon(Icons.lock_rounded, color: _accent.withOpacity(0.5), size: 20)
                    : AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: _ccArrow, size: 24),
                      ),
                  const SizedBox(width: 8),
                  
                  // 2. Sol: Anlam (Sayı prefixi yok)
                  Expanded(
                    child: Text(
                      anlam,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ccAnlam,
                      ),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  
                  // 3. Sağ Taraf
                  const SizedBox(width: 12),
                  // Muzâri
                  SizedBox(
                    width: 75,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(muzari,
                          style: GoogleFonts.scheherazadeNew(
                              fontSize: 25, 
                              color: _ccMuzari,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          textDirection: ui.TextDirection.rtl),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Mâzi (En Sağ)
                  SizedBox(
                    width: 75,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(mazi,
                          style: GoogleFonts.scheherazadeNew(
                              fontSize: 25, 
                              color: _ccMazi,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          textDirection: ui.TextDirection.rtl),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Detay ──
          if (expanded) _buildDetail(verb, verbId),
        ],
      ),
    );
  }

  // ─────────────────── DETAY PANEL ──────────────────────────────
  Widget _buildDetail(Map<String, dynamic> verb, int verbId) {
    final anlamlar = verb['anlamlar'] as List<dynamic>? ?? [];
    final emsile24 = verb['emsile_24'] as List<dynamic>? ?? [];

    return Container(
      color: _detailBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: _divColor),

          // ── Gelişmiş Kompakt Anlam ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: anlamlar.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _labelClr.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _labelClr.withValues(alpha: 0.2), 
                    width: 1.0,
                  ),
                ),
                child: Text(a.toString(),
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _labelClr,
                        fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ),
          Divider(height: 1, color: _divColor),

          // ── 24 Sığa Grid ──
          _buildSigaSection(emsile24, verb, verbId),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─────────────────── 24 SIĞA + İNLİNE ÇEKİM ─────────────────
  Widget _buildSigaSection(List<dynamic> items, Map<String, dynamic> verb, int verbId) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final gap   = 4.0;
      final hPad  = 6.0;
      final cardW = (constraints.maxWidth - hPad * 2 - gap * 3) / 4;

      // Satırlar: 4'lü gruplar
      final rows = <List<dynamic>>[];
      for (int i = 0; i < items.length; i += 4) {
        rows.add(items.sublist(i, (i + 4) < items.length ? i + 4 : items.length));
      }

      final openKey = _openConj[verbId];
      final openRow = openKey != null ? (_conjToRow[openKey] ?? -1) : -1;

      return Container(
        color: _detailBg,
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
        child: Column(
          children: rows.asMap().entries.map((entry) {
            final rowIdx   = entry.key;
            final rowItems = entry.value;

            return Column(
              children: [
                // Kart satırı
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    textDirection: ui.TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(4, (col) {
                      final itemIdx = rowIdx * 4 + col; // 4'lü düzende index
                      final hasItem = col < rowItems.length;
                      if (!hasItem) {
                        return SizedBox(width: col < 3 ? cardW + gap : cardW);
                      }
                      final conjKey = _sigaToConj[itemIdx];
                      final hasData = conjKey != null && _cekim(verb, conjKey).isNotEmpty;
                      
                      return Padding(
                        padding: EdgeInsets.only(left: col < 3 ? gap : 0),
                        child: SizedBox(
                          width: cardW,
                          child: _sigaCard(
                            item: rowItems[col],
                            conjKey: conjKey,
                            isConjOpen: openKey == conjKey && conjKey != null,
                            hasData: hasData,
                            onConjTap: !hasData ? null : () {
                              setState(() {
                                if (_openConj[verbId] == conjKey) {
                                  _openConj[verbId] = null;
                                } else {
                                  _openConj[verbId] = conjKey;
                                }
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Bu satırın altında çekim tablosu (eğer bu satırda açık bir çekim varsa)
                if (openRow == rowIdx && openKey != null)
                  _buildInlineConjGrid(_cekim(verb, openKey), openKey),
              ],
            );
          }).toList(),
        ),
      );
    });
  }

  String _shortName(String name) {
    if (name.contains('Tekîd-i Nefy-i İstikbâl')) return 'Tek. N. İstik.';
    if (name.contains('İsm-i Zaman / Mekân')) return 'Zaman/Mekân';
    if (name.contains('Cehd-i Müstağrak')) return 'C. Müstağrak';
    if (name.contains('Cehd-i Mutlak')) return 'C. Mutlak';
    if (name.contains('Müb. İsm-i Fâil')) return 'Müb. İ. Fâil';
    if (name.contains('Taaccüb-i Evvel')) return 'Taaccüb 1';
    if (name.contains('Taaccüb-i Sânî')) return 'Taaccüb 2';
    if (name.contains('Nefy-i İstikbâl')) return 'Nef. İstik.';
    return name;
  }

  // ─────────────────── SIĞA KARTI ──────────────────────────────
  Widget _sigaCard({
    required dynamic item,
    required String? conjKey,
    required bool isConjOpen,
    required bool hasData,
    required VoidCallback? onConjTap,
  }) {
    final isim    = _shortName(item['isim']?.toString() ?? '');
    final arapca  = item['arapca']?.toString() ?? '';
    final hasConj = conjKey != null && hasData;

    final headerBg = isConjOpen ? _btnOpen : _labelClr.withValues(alpha: 0.15);
    final headerTxt = isConjOpen ? Colors.white : _labelClr;

    return GestureDetector(
      onTap: onConjTap,
      child: Container(
        height: 85, // Kompakt yükseklik
        decoration: BoxDecoration(
          color: isConjOpen ? _btnOpen.withValues(alpha: 0.05) : _sigaBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isConjOpen ? _accent : _sigaBrd,
            width: isConjOpen ? 1.5 : 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Üst başlık şeridi (Sabit boyut) ──
                Container(
                  height: 20,
                  width: double.infinity,
                  color: headerBg,
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isim,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: headerTxt,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                // ── Orta: Arapça metin (Sabit boyut, tam ortalanmış) ──
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          arapca,
                          textDirection: ui.TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.scheherazadeNew(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isConjOpen ? _accent : _arabicClr,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── Alt: Küçük Gösterge Oku (Sadece çekimi olanlarda) ──
            if (hasConj)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 12,
                  color: _btnOpen.withValues(alpha: 0.8),
                  child: Icon(
                    isConjOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── İNLİNE ÇEKİM GRİDİ ──────────────────────
  Widget _buildInlineConjGrid(List<Map<String, dynamic>> entries, String key) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Başlık metni
    final titleMap = {
      'mazi':   'Fiil-i Mâzi — Muttasıl Çekimler',
      'muzari': 'Fiil-i Muzâri — Muttasıl Çekimler',
      'emir':   'Emr-i Hâzır — Muttasıl Çekimler',
    };

    final rows = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < entries.length; i += 3) {
      rows.add(entries.sublist(
          i, (i + 3) < entries.length ? i + 3 : entries.length));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _conjRowBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withValues(alpha: 0.3), width: 0.9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Başlık
          Container(
            color: _btnOpen,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_chart_rounded, size: 13, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  titleMap[key] ?? 'Çekimler',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Grid
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final rowData = e.value;
            return Column(
              children: [
                Row(
                  textDirection: ui.TextDirection.rtl,
                  children: List.generate(3, (col) {
                    if (col < rowData.length) {
                      String text = _extractArabicFromSahis(rowData[col]);
                      return Expanded(
                        child: _conjCell(
                          text,
                          leftBorder: col < 2,
                        ),
                      );
                    }
                    return Expanded(
                        child: Container(height: 54, color: _conjRowBg));
                  }),
                ),
                if (!isLast)
                  Divider(height: 1, thickness: 0.7, color: _divColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Sadece Arapça metni çıkar
  String _extractArabicFromSahis(Map<String, dynamic> entry) {
    String source = entry['arapca']?.toString() ?? '';
    // Eğer arapca alanı boş veya hatalıysa ana sahis içinden bul
    if (source.trim().isEmpty) {
      source = entry['sahis']?.toString() ?? '';
    }
    
    if (source.trim().isEmpty) return '';
    
    // Tüm arapça harf bloklarını al (hareke ve şeddeler dahil)
    final arabicMatches = RegExp(r'[\u0600-\u06FF\u064B-\u065F\u0670\u0653-\u0655]+').allMatches(source);
    if (arabicMatches.isNotEmpty) {
      String arabicStr = arabicMatches.map((m) => m.group(0)).join(' ').trim();
      
      // Sadece standart arapça zamir kelimelerini temizle, fiilin köküne/kendisine dokunma
      final words = arabicStr.split(' ').where((w) {
        String plain = w.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]'), '');
        const plainPronouns = [
          'هو', 'هما', 'هم', 'هي', 'هن', 
          'أنت', 'انت', 'أنتما', 'انتما', 'أنتم', 'انتم', 
          'أنتن', 'انتن', 'أنا', 'ana', 'انا', 'نحن'
        ];
        return !plainPronouns.contains(plain) && w.trim().isNotEmpty;
      }).toList();
      
      // NOT: Önceden olan ardışık tekrar silme / deduplication kodu KASITLI OLARAK KALDIRILDI.
      // İnbeheme gibi şeddeli veya tekrarlı kalıpların doğru çekimlenmesi için tüm kelimeler korunur.
      return words.join(' ').trim();
    }
    
    return source.trim();
  }

  Widget _conjCell(String text, {bool leftBorder = true}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _cellBg,
        border: Border(
          left: leftBorder
              ? BorderSide(color: _divColor, width: 0.7)
              : BorderSide.none,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text,
                style: GoogleFonts.scheherazadeNew(
                    fontSize: 21, color: _arabicClr,
                    fontWeight: FontWeight.w500),
                textDirection: ui.TextDirection.rtl,
                textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF007AFF), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ),
      ],
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Premium İçerik',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                _buildPremiumFeature('7000\'den fazla fiilin 24 sığa Emsile-i Muhtelife çekimlerini açın'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF007AFF), // Apple Blue
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onPremiumTap?.call();
                    },
                    child: Text(
                      'Premium\'a Yükselt',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.onLoadFreeTap?.call();
                  },
                  child: Text(
                    'Ücretsiz Fiiller',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? Colors.white54 : const Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
