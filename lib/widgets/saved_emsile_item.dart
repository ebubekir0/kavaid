import 'package:flutter/material.dart';

import '../models/custom_word.dart';
import '../services/emsile_database_service.dart';
import 'emsile_view.dart';

/// Kayıtlı listede bir emsile fiilini, emsile sayfasındaki satırın aynısıyla
/// gösterir (açılınca 24 sığa ve çekimler). Fiilin tam verisi kayıtta değil
/// emsile veritabanında durur; yalnızca kimliği saklanır.
class SavedEmsileItem extends StatefulWidget {
  const SavedEmsileItem({
    super.key,
    required this.word,
    required this.isDarkMode,
    required this.onRemove,
  });

  final CustomWord word;
  final bool isDarkMode;
  final VoidCallback onRemove;

  @override
  State<SavedEmsileItem> createState() => _SavedEmsileItemState();
}

class _SavedEmsileItemState extends State<SavedEmsileItem> {
  late final Future<Map<String, dynamic>?> _verb = _load();

  Future<Map<String, dynamic>?> _load() async {
    final id = widget.word.wordData?['id'];
    if (id is! int) return null;
    try {
      return await EmsileDatabaseService.instance.getById(id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _verb,
      builder: (context, snapshot) {
        final verb = snapshot.data;
        if (verb == null) return _fallback();
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                EmsileView(
                  isDarkMode: widget.isDarkMode,
                  verbs: [verb],
                  isPremium: true,
                  isSearchMode: true,
                  onRemove: widget.onRemove,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Veritabanı henüz hazır değilse kayıttaki özet bilgiyle sade bir satır.
  Widget _fallback() {
    final data = widget.word.wordData ?? const {};
    final dark = widget.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? const Color(0xFF48484A) : const Color(0xFFD0D0D0),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (data['anlam'] ?? widget.word.turkish).toString().toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white70 : const Color(0xFF3D5C80),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${data['muzari'] ?? ''}   ${data['mazi'] ?? ''}',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.bookmark, color: Color(0xFF007AFF)),
          ),
        ],
      ),
    );
  }
}
