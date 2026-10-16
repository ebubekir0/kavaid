import 'dart:async';

import 'package:flutter/material.dart';

import '../models/custom_word.dart';
import '../services/auth_service.dart';
import '../services/custom_word_service.dart';
import '../services/language_service.dart';

/// Kelime / Kur'an kelimesi / emsile fiili için kaydet (yer imi) düğmesi.
///
/// Üç sözlükte de aynı davranır: giriş yoksa uyarır; tek liste varsa doğrudan
/// ekler/çıkarır, birden çok liste varsa liste seçtirir. Durum, kelimenin
/// kayıtlı olduğu listelere göre güncel tutulur.
class SaveButton extends StatefulWidget {
  const SaveButton({
    super.key,
    required this.target,
    required this.isDarkMode,
    this.onRemove,
    this.checkDelay = Duration.zero,
  });

  final SaveTarget target;
  final bool isDarkMode;

  /// Verilirse düğme "listede" görünür ve dokununca bu çağrılır
  /// (kayıtlı listeler ekranında kelimeyi o listeden çıkarmak için).
  final VoidCallback? onRemove;

  /// Uzun listelerde ilk çizimi yavaşlatmamak için kayıt durumunu bu kadar
  /// gecikmeyle sorgular.
  final Duration checkDelay;

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  final CustomWordService _service = CustomWordService();
  bool _isSaved = false;
  Timer? _timer;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.onRemove == null) {
      _timer = Timer(widget.checkDelay, () {
        if (mounted) _refresh();
      });
      _subscription = _service.onWordsChanged.listen((_) {
        if (mounted) _refresh();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.arabic != widget.target.arabic ||
        oldWidget.target.harekeli != widget.target.harekeli) {
      _isSaved = false;
      if (widget.onRemove == null) _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final ids = await _service.getListsWithTarget(widget.target);
    if (!mounted) return;
    setState(() => _isSaved = ids.isNotEmpty);
  }

  Future<void> _onTap() async {
    if (!AuthService().isSignedIn) {
      _showLoginRequired();
      return;
    }

    await _service.getOrCreateDefaultList();
    final lists = await _service.getLists();
    if (!mounted) return;

    if (lists.length <= 1) {
      // Tek liste: doğrudan ekle / çıkar
      final id = lists.isEmpty
          ? (await _service.getOrCreateDefaultList()).id
          : lists.first.id;
      if (_isSaved) {
        await _service.removeTargetFromList(widget.target, id);
      } else {
        await _service.addTarget(widget.target, id);
      }
      if (mounted) await _refresh();
    } else {
      await _showListSheet();
    }
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService().isEnglish
              ? 'Please log in or sign up first'
              : 'Lütfen önce kayıt olup giriş yapın.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showListSheet() async {
    final lists = await _service.getLists();
    final savedIn = (await _service.getListsWithTarget(widget.target)).toSet();

    // Çok kelimeli listeler üstte
    final counts = <String, int>{};
    for (final list in lists) {
      counts[list.id] = (await _service.getWordsByList(list.id)).length;
    }
    lists.sort((a, b) {
      final byCount = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
      return byCount != 0 ? byCount : a.createdAt.compareTo(b.createdAt);
    });

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) => Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Listeye Ekle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      final selected = savedIn.contains(list.id);
                      return ListTile(
                        title: Text(
                          list.name,
                          style: TextStyle(
                            color: dark ? Colors.white : Colors.black,
                          ),
                        ),
                        leading: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: selected
                              ? const Color(0xFF007AFF)
                              : (dark ? Colors.grey : Colors.black54),
                        ),
                        onTap: () async {
                          if (selected) {
                            await _service.removeTargetFromList(
                              widget.target,
                              list.id,
                            );
                            savedIn.remove(list.id);
                          } else {
                            await _service.addTarget(widget.target, list.id);
                            savedIn.add(list.id);
                          }
                          setSheetState(() {});
                          if (mounted) await _refresh();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final removeMode = widget.onRemove != null;
    final saved = removeMode || _isSaved;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: removeMode ? widget.onRemove : _onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(
            saved ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
            color: saved
                ? const Color(0xFF007AFF)
                : (widget.isDarkMode
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70)),
          ),
        ),
      ),
    );
  }
}
