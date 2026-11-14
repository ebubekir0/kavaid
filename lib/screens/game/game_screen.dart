import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kavaid/l10n/l10n.dart';

import '../../services/word_game_service.dart';
import '../../widgets/game/letter_wheel.dart';

/// Oyunun sahnesi: her 10 bölümde arka plan değişir. Görseller paylaşım kartıyla ortaktır
/// (assets/share_backgrounds). [dark]: sahne koyu, yazılar beyaz.
class _Scene {
  const _Scene(this.file, {required this.dark, required this.accent});

  final String file;
  final bool dark;
  final Color accent;

  String get asset => 'assets/share_backgrounds/$file.jpg';
}

const _scenes = [
  _Scene('night', dark: true, accent: Color(0xFFE9C46A)),
  _Scene('emerald', dark: true, accent: Color(0xFFE9C46A)),
  _Scene('dusk', dark: true, accent: Color(0xFFF4CF96)),
  _Scene('sea', dark: false, accent: Color(0xFF6E5FA8)),
  _Scene('desert', dark: false, accent: Color(0xFF9A5B34)),
  _Scene('olive', dark: false, accent: Color(0xFF5F6F3A)),
  _Scene('flowers', dark: false, accent: Color(0xFFB4626F)),
  _Scene('parchment', dark: false, accent: Color(0xFF8C6A2E)),
];

const _ink = Color(0xFF1C1C1E);
const _green = Color(0xFF34C759);
const _red = Color(0xFFFF3B30);
const _blue = Color(0xFF007AFF);
const _gold = Color(0xFFFFB800);

/// Kelime oyunu (Oyun sekmesi): ipucu olarak kelimenin anlamı gösterilir, oyuncu çarktaki
/// harfleri sırayla birleştirerek Arapça kelimeyi kurar. Bir bölüm 5 kelimedir.
///
/// Kurallar ve kayıt [WordGameService]'te; bölümler `assets/data/oyun/<dil>.json`.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.isDarkMode,
    required this.lang,
    this.bottomPadding = 0,
    this.now,
  });

  final bool isDarkMode;

  /// Sözlük dili (ipuçlarının dili): tr, en, ar, id, ms, ur.
  final String lang;

  /// Alt gezinme çubuğu ve reklam için bırakılan boşluk.
  final double bottomPadding;

  /// Testler için saat.
  final DateTime Function()? now;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  List<List<GameWord>>? _levels;
  late GameProgress _progress;

  // Ekranda gösterilen bölüm ve soru. Kayıt bir adım önde olabilir: çözülen kelime ekranda
  // dururken sıradaki soru çoktan kaydedilmiştir.
  int _lv = 0;
  int _q = 0;
  int _revealed = 0;

  List<String> _wheel = const [];
  final List<int> _selected = [];
  int _shuffle = 0;

  /// Bu bölümdeki yanlış deneme ve ipucu sayısı (yıldızı belirler).
  int _slips = 0;
  bool _solved = false;
  bool _error = false;

  /// Bölüm sonu kartı açıksa kazanılan yıldız.
  int? _doneStars;
  int _doneBonus = 0;

  String? _toast;
  Timer? _advanceTimer;
  Timer? _toastTimer;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) _load();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _toastTimer?.cancel();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final first = _levels == null;
    final levels = await WordGameService.loadLevels(widget.lang);
    final progress = first ? await WordGameService.loadProgress() : _progress;
    if (!mounted) return;
    _advanceTimer?.cancel();
    setState(() {
      _levels = levels;
      _progress = progress;
      _lv = progress.level;
      _q = progress.question.clamp(0, _words.length - 1);
      _revealed = progress.revealed.clamp(0, _word.letters.length);
      _doneStars = null;
      _resetQuestion();
    });
  }

  List<GameWord> get _words => _levels![_lv % _levels!.length];
  GameWord get _word => _words[_q];
  _Scene get _scene => _scenes[(_lv ~/ 10) % _scenes.length];

  void _resetQuestion() {
    _selected.clear();
    _solved = false;
    _error = false;
    _wheel = WordGameService.wheelLetters(_word, level: _lv, question: _q, shuffle: _shuffle);
  }

  void _add(int i) => setState(() => _selected.add(i));

  void _removeLast() {
    if (_selected.isNotEmpty) setState(_selected.removeLast);
  }

  void _clear() {
    if (_selected.isNotEmpty && !_solved) setState(_selected.clear);
  }

  /// Parmak kalktı: sürükleyerek kurulan kelime hemen denenir; tek tek dokunarak kurulan
  /// kelime son harfte denenir.
  void _end(bool swiped) {
    if (_solved || _error || _selected.isEmpty) return;
    if (!swiped && _selected.length < _word.letters.length) return;
    final formed = _selected.map((i) => _wheel[i]).join();
    formed == _word.answer ? _correct() : _wrong();
  }

  void _wrong() {
    HapticFeedback.heavyImpact();
    setState(() {
      _error = true;
      if (_selected.length == _word.letters.length) _slips++;
    });
    _shake.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _error = false;
        _selected.clear();
      });
    });
  }

  void _correct() {
    HapticFeedback.mediumImpact();
    final p = _progress;
    p.points += WordGameService.wordPoints;
    final newDay = WordGameService.registerDay(p, (widget.now ?? DateTime.now)());
    final last = _q + 1 >= _words.length;
    final stars = WordGameService.starsFor(_slips);
    if (last) {
      _doneBonus = WordGameService.levelBonus(stars);
      p.points += _doneBonus;
      p.level = _lv + 1;
      p.question = 0;
    } else {
      p.question = _q + 1;
    }
    p.revealed = 0;
    unawaited(WordGameService.saveProgress(p));
    setState(() => _solved = true);
    if (newDay) _showToast(l10n.oyunGunlukSeri(p.streak, WordGameService.dailyBonus));

    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        if (last) {
          _doneStars = stars;
        } else {
          _q++;
          _revealed = 0;
          _shuffle = 0;
          _resetQuestion();
        }
      });
    });
  }

  void _nextLevel() {
    setState(() {
      _doneStars = null;
      _lv = _progress.level;
      _q = 0;
      _revealed = 0;
      _slips = 0;
      _shuffle = 0;
      _resetQuestion();
    });
  }

  void _hint() {
    if (_solved || _doneStars != null || _revealed >= _word.letters.length) return;
    if (_progress.points < WordGameService.hintCost) {
      _showToast(l10n.oyunPuanYetmiyor(WordGameService.hintCost));
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _progress.points -= WordGameService.hintCost;
      _revealed++;
      _progress.revealed = _revealed;
      _slips++;
    });
    unawaited(WordGameService.saveProgress(_progress));
  }

  void _shuffleWheel() {
    if (_solved || _doneStars != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _shuffle++;
      _selected.clear();
      _wheel = WordGameService.wheelLetters(_word, level: _lv, question: _q, shuffle: _shuffle);
    });
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_levels == null) {
      return ColoredBox(
        color: widget.isDarkMode ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final scene = _scene;
    final fg = scene.dark ? Colors.white : const Color(0xFF2B2118);
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: const ['ScheherazadeNew'],
        color: fg,
        decoration: TextDecoration.none,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Image.asset(
              scene.asset,
              key: ValueKey(scene.file),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          ColoredBox(
            color: scene.dark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.10),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              child: LayoutBuilder(builder: (context, box) => _board(box, scene, fg)),
            ),
          ),
          if (_doneStars != null)
            _LevelDone(
              isDarkMode: widget.isDarkMode,
              bottomPadding: widget.bottomPadding,
              stars: _doneStars!,
              bonus: _doneBonus,
              words: _words,
              onNext: _nextLevel,
            ),
        ],
      ),
    );
  }

  Widget _board(BoxConstraints box, _Scene scene, Color fg) {
    final wheelSize = math.min(box.maxWidth - 72, box.maxHeight * 0.46).clamp(180.0, 300.0);
    return Column(
      children: [
        _topBar(scene, fg),
        const SizedBox(height: 12),
        _dots(scene, fg),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: box.maxWidth - 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_clueCard(scene, fg), const SizedBox(height: 18), _boxes(scene)],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 44, child: Center(child: _preview(scene, fg))),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: wheelSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: LetterWheel(
                  key: ValueKey('wheel-$_lv-$_q-$_shuffle'),
                  letters: _wheel,
                  selected: _selected,
                  size: wheelSize,
                  accent: scene.accent,
                  enabled: !_solved && !_error && _doneStars == null,
                  error: _error,
                  onAdd: _add,
                  onRemoveLast: _removeLast,
                  onEnd: _end,
                  onMiss: _clear,
                ),
              ),
              Positioned(
                left: 14,
                bottom: 0,
                child: _RoundButton(
                  key: const ValueKey('game-shuffle'),
                  scene: scene,
                  icon: Icons.shuffle_rounded,
                  tooltip: l10n.oyunKaristir,
                  onTap: _shuffleWheel,
                ),
              ),
              Positioned(
                right: 14,
                bottom: 0,
                child: _RoundButton(
                  key: const ValueKey('game-hint'),
                  scene: scene,
                  icon: Icons.lightbulb_outline_rounded,
                  label: '${WordGameService.hintCost}',
                  tooltip: l10n.oyunHarfAc,
                  onTap: _hint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _topBar(_Scene scene, Color fg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _Pill(
            scene: scene,
            child: Text(
              l10n.oyunBolum(_lv + 1),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          if (_progress.streak > 0) ...[
            _Pill(
              scene: scene,
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFFF9500),
              child: Text(
                '${_progress.streak}',
                key: const ValueKey('game-streak'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _Pill(
            scene: scene,
            icon: Icons.stars_rounded,
            iconColor: _gold,
            child: Text(
              '${_progress.points}',
              key: const ValueKey('game-points'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Bölümdeki 5 kelimenin durumu.
  Widget _dots(_Scene scene, Color fg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _words.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _q ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i < _q || (i == _q && _solved)
                  ? scene.accent
                  : fg.withValues(alpha: i == _q ? 0.85 : 0.3),
            ),
          ),
      ],
    );
  }

  Widget _clueCard(_Scene scene, Color fg) {
    final rtl = widget.lang == 'ar' || widget.lang == 'ur';
    Widget clue({required bool small}) => Text(
      _word.clue,
      key: small ? null : const ValueKey('game-clue'),
      textAlign: TextAlign.center,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      maxLines: small ? 2 : 4,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: rtl ? 'ScheherazadeNew' : 'Inter',
        fontSize: (rtl ? 24.0 : 21.0) * (small ? 0.72 : 1),
        fontWeight: FontWeight.w600,
        height: rtl ? 1.6 : 1.35,
        color: fg.withValues(alpha: small ? 0.8 : 1),
      ),
    );
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: _glass(scene, radius: 24),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _solved
            ? Column(
                key: ValueKey('solved-$_lv-$_q'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _word.display,
                    key: const ValueKey('game-solved-word'),
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'ArefRuqaa',
                      fontFamilyFallback: const ['ScheherazadeNew'],
                      fontWeight: FontWeight.w700,
                      fontSize: 46,
                      height: 1.5,
                      color: fg,
                    ),
                  ),
                  clue(small: true),
                ],
              )
            : KeyedSubtree(key: ValueKey('clue-$_lv-$_q'), child: clue(small: false)),
      ),
    );
  }

  /// Cevabın harf kutuları (sağdan sola).
  Widget _boxes(_Scene scene) {
    final onAccent = ThemeData.estimateBrightnessForColor(scene.accent) == Brightness.dark
        ? Colors.white
        : _ink;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        return Transform.translate(offset: Offset(math.sin(t * math.pi * 4) * 10 * (1 - t), 0), child: child);
      },
      // 6 harfli kelime dar ekrana sığmazsa kutular küçülür.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _word.letters.length; i++)
                () {
                  var letter = '';
                  var fill = Colors.white.withValues(alpha: scene.dark ? 0.92 : 0.82);
                  var color = _ink;
                  if (_solved) {
                    letter = _word.letters[i];
                    fill = _green;
                    color = Colors.white;
                  } else if (i < _selected.length) {
                    letter = _wheel[_selected[i]];
                    fill = _error ? _red : scene.accent;
                    color = _error ? Colors.white : onAccent;
                  } else if (i < _revealed) {
                    letter = _word.letters[i];
                    color = _blue;
                  }
                  return AnimatedContainer(
                    key: ValueKey('game-box-$i'),
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(11),
                      // Açık sahnede beyaz kutu zeminden ayrılsın.
                      border: scene.dark ? null : Border.all(color: Colors.black.withValues(alpha: 0.10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: color,
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }

  /// Çarkın üstünde: kurulmakta olan kelime, bitişik yazıyla. İlk soruda oyunun nasıl
  /// oynandığı yazar.
  Widget _preview(_Scene scene, Color fg) {
    // Bildirim (günlük seri, puan yetmiyor) varsa bu satırda o görünür.
    if (_toast != null) return _toastView();
    if (_selected.isEmpty || _solved) {
      final showHelp = _lv == 0 && _q == 0 && !_solved;
      return AnimatedOpacity(
        opacity: showHelp ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            showHelp ? l10n.oyunNasil : '',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.9)),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      height: 42,
      decoration: BoxDecoration(
        color: _error ? _red : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          _selected.map((i) => _wheel[i]).join(),
          key: const ValueKey('game-preview'),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'ScheherazadeNew',
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: _error ? Colors.white : _ink,
          ),
        ),
      ),
    );
  }

  Widget _toastView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        _toast ?? '',
        key: const ValueKey('game-toast'),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

BoxDecoration _glass(_Scene scene, {required double radius}) => BoxDecoration(
  color: scene.dark ? Colors.black.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.62),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white.withValues(alpha: scene.dark ? 0.20 : 0.75)),
);

/// Üst çubuktaki küçük bilgi hapı (bölüm, seri, puan).
class _Pill extends StatelessWidget {
  const _Pill({required this.scene, required this.child, this.icon, this.iconColor});

  final _Scene scene;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: _glass(scene, radius: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: iconColor), const SizedBox(width: 5)],
          child,
        ],
      ),
    );
  }
}

/// Çarkın yanındaki yuvarlak düğme (karıştır, harf aç).
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.scene,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
  });

  final _Scene scene;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fg = scene.dark ? Colors.white : const Color(0xFF2B2118);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _glass(scene, radius: 26),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: fg),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm sonu kartı: yıldızlar, kazanılan puan ve bölümde öğrenilen 5 kelime.
class _LevelDone extends StatelessWidget {
  const _LevelDone({
    required this.isDarkMode,
    required this.bottomPadding,
    required this.stars,
    required this.bonus,
    required this.words,
    required this.onNext,
  });

  final bool isDarkMode;
  final double bottomPadding;
  final int stars;
  final int bonus;
  final List<GameWord> words;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : _ink;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: fg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: EdgeInsets.only(bottom: i == 1 ? 8 : 0),
                              child: Icon(
                                Icons.star_rounded,
                                size: i == 1 ? 52 : 42,
                                color: i < stars ? _gold : fg.withValues(alpha: 0.15),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.oyunBolumTamam,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.oyunArtiPuan(bonus),
                        key: const ValueKey('game-level-bonus'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _gold),
                      ),
                      const SizedBox(height: 14),
                      for (final w in words)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            textDirection: TextDirection.ltr,
                            children: [
                              Expanded(
                                child: Text(
                                  w.clue,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, color: fg.withValues(alpha: 0.65)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                w.display,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'ScheherazadeNew',
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('game-next-level'),
                          onPressed: onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontFamilyFallback: ['ScheherazadeNew'],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(l10n.oyunSonrakiBolum),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
