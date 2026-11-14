import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_service.dart';
import '../services/promo_code_service.dart';

/// Kurucu paneli: promosyon ve sınıf kodları.
///
/// Tek ekran: üstte "Yeni kod", altında kodların listesi (kime verildi, kaç
/// kişi kullandı). Biten ve eski tek kullanımlık kodlar menüden toplu silinir.
/// Açılışta yalnız kod listesi okunur (eski panel istatistik sorgularıyla geç
/// açılıyordu).
class AdminConsoleScreen extends StatefulWidget {
  final double bottomPadding;
  final double topPadding;

  const AdminConsoleScreen({
    super.key,
    this.bottomPadding = 0,
    this.topPadding = 0,
  });

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

enum _Filter { active, finished, all }

class _Code {
  final String code;
  final String label;
  final int used;
  final int max;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const _Code({
    required this.code,
    required this.label,
    required this.used,
    required this.max,
    required this.isActive,
    required this.createdAt,
    required this.expiresAt,
  });

  factory _Code.from(Map<String, dynamic> d) => _Code(
        code: (d['code'] as String?) ?? (d['id'] as String?) ?? '?',
        label: (d['label'] as String?) ?? '',
        used: (d['usedCount'] as num?)?.toInt() ?? 0,
        max: (d['maxUses'] as num?)?.toInt() ?? 1,
        isActive: d['isActive'] == true,
        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
        expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      );

  bool get isFull => used >= max;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUsable => isActive && !isFull && !isExpired;

  /// Eski kampanyalardan kalan tek kişilik kodlar.
  bool get isSingleUse => max <= 1;

  String get status => !isActive
      ? 'Kapalı'
      : isFull
          ? 'Doldu'
          : isExpired
              ? 'Süresi doldu'
              : 'Aktif';
}

String _date(DateTime? d) => d == null
    ? '—'
    : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final _service = PromoCodeService();
  List<_Code>? _codes;
  bool _loading = true;
  bool _error = false;
  _Filter _filter = _Filter.active;

  @override
  void initState() {
    super.initState();
    if (AdminService().isFounder()) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final raw = await _service.listPromoCodes();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = raw == null;
      _codes = raw?.map(_Code.from).toList();
    });
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : null,
      ));
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack(message);
  }

  List<_Code> get _visible {
    final all = _codes ?? const <_Code>[];
    switch (_filter) {
      case _Filter.active:
        return all.where((c) => c.isUsable).toList();
      case _Filter.finished:
        return all.where((c) => !c.isUsable).toList();
      case _Filter.all:
        return all;
    }
  }

  // ---------------------------------------------------------------- Yeni kod

  Future<void> _openCreateSheet() async {
    final labelCtrl = TextEditingController();
    var people = 100;
    var count = 1;
    var busy = false;

    final created = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget choices(List<int> values, int selected, String Function(int) text,
                  void Function(int) onPick) =>
              Wrap(
                spacing: 8,
                children: [
                  for (final v in values)
                    ChoiceChip(
                      label: Text(text(v)),
                      selected: v == selected,
                      onSelected: busy ? null : (_) => setSheet(() => onPick(v)),
                    ),
                ],
              );

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yeni kod', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Her kod, giren kişiye 30 gün Premium verir.',
                    style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 16),
                TextField(
                  controller: labelCtrl,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Kime veriyorsun? (isteğe bağlı)',
                    hintText: 'ör. @nahwu_pedia veya ITHLA 18 Aralık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Kaç kişi kullanabilsin?'),
                const SizedBox(height: 6),
                choices(const [1, 30, 100, 300], people, (v) => '$v kişi',
                    (v) => people = v),
                const SizedBox(height: 14),
                const Text('Kaç kod?'),
                const SizedBox(height: 6),
                choices(const [1, 10, 25, 50], count, (v) => '$v', (v) => count = v),
                if (count > 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Hepsi aynı etiketle oluşur; dağıttıkça listede tek tek etiketini değiştirebilirsin.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            setSheet(() => busy = true);
                            final codes = await _service.createBatchPromoCodes(
                              count: count,
                              maxUses: people,
                              label: labelCtrl.text,
                            );
                            if (ctx.mounted) Navigator.pop(ctx, codes);
                          },
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add),
                    label: Text(busy
                        ? 'Oluşturuluyor…'
                        : count == 1
                            ? 'Oluştur ve kopyala'
                            : '$count kod oluştur ve kopyala'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    labelCtrl.dispose();

    if (!mounted || created == null) return;
    if (created.isEmpty) {
      _snack('Kod oluşturulamadı', error: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: created.join('\n')));
    if (!mounted) return;
    if (created.length == 1) {
      _snack('Kod kopyalandı: ${created.first}');
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${created.length} kod oluşturuldu'),
          content: SizedBox(
            width: double.maxFinite,
            height: 260,
            child: ListView(
              children: [
                const Text('Hepsi panoya kopyalandı.'),
                const SizedBox(height: 8),
                for (final c in created)
                  SelectableText(c,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
          ],
        ),
      );
    }
    await _load();
  }

  // ------------------------------------------------------- Tek kod işlemleri

  Future<void> _editLabel(_Code c) async {
    final ctrl = TextEditingController(text: c.label);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${c.code} kime verildi?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ör. @nahwu_pedia'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Kaydet')),
        ],
      ),
    );
    ctrl.dispose();
    if (value == null) return;
    final ok = await _service.setPromoCodeLabel(c.code, value);
    if (!mounted) return;
    ok ? await _load() : _snack('Etiket kaydedilemedi', error: true);
  }

  Future<void> _deactivate(_Code c) async {
    final ok = await _service.deactivatePromoCode(c.code);
    if (!mounted) return;
    _snack(ok ? '${c.code} kapatıldı: artık kullanılamaz' : 'Kapatılamadı', error: !ok);
    if (ok) await _load();
  }

  Future<bool> _confirmDelete(int n, String what) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$n kod silinsin mi?'),
        content: Text(
          '$what kalıcı olarak silinecek, geri alınamaz.\n\n'
          'Bu kodları daha önce kullananların Premium süresi etkilenmez.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _delete(List<_Code> codes, String what) async {
    if (codes.isEmpty) return;
    if (!await _confirmDelete(codes.length, what)) return;
    setState(() => _loading = true);
    final n = await _service.deletePromoCodes(codes.map((c) => c.code).toList());
    if (!mounted) return;
    _snack(n == codes.length ? '$n kod silindi' : '$n/${codes.length} kod silindi',
        error: n != codes.length);
    await _load();
  }

  // ----------------------------------------------------------------- Temizle

  Future<void> _openCleanup() async {
    final all = _codes ?? const <_Code>[];
    final finished = all.where((c) => !c.isUsable).toList();
    final single = all.where((c) => c.isSingleUse).toList();
    final pick = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Eski kodları temizle'),
              subtitle: Text('Silinen kodlar listeden de veritabanından da kalkar.'),
            ),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: Text('Biten kodlar (${finished.length})'),
              subtitle: const Text('Kapatılmış, dolmuş ya da süresi geçmiş'),
              enabled: finished.isNotEmpty,
              onTap: () => Navigator.pop(ctx, 1),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: Text('Tek kişilik eski kodlar (${single.length})'),
              subtitle: const Text('Eski kampanya ve toplu üretimden kalan 1 kişilik kodlar'),
              enabled: single.isNotEmpty,
              onTap: () => Navigator.pop(ctx, 2),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (pick == 1) await _delete(finished, 'Biten ${finished.length} kod');
    if (pick == 2) await _delete(single, 'Tek kişilik ${single.length} eski kod');
  }

  // ------------------------------------------------------------------ Arayüz

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!AdminService().isFounder()) {
      return const Scaffold(body: Center(child: Text('Bu alan yalnız kurucuya açık')));
    }

    final all = _codes ?? const <_Code>[];
    final activeCount = all.where((c) => c.isUsable).length;
    final finishedCount = all.length - activeCount;
    final totalUses = all.fold<int>(0, (s, c) => s + c.used);
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promosyon Kodları'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Eski kodları temizle',
            onPressed: _loading || all.isEmpty ? null : _openCleanup,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomPadding + 24),
          children: [
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _codes == null
                          ? 'Kodlar yükleniyor…'
                          : '$activeCount aktif kod · toplam $totalUses kişi kullandı',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openCreateSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni kod'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_Filter>(
              segments: [
                ButtonSegment(value: _Filter.active, label: Text('Aktif ($activeCount)')),
                ButtonSegment(value: _Filter.finished, label: Text('Biten ($finishedCount)')),
                ButtonSegment(value: _Filter.all, label: Text('Tümü (${all.length})')),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: 8),
            if (_loading && _codes == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Kodlar yüklenemedi. İnternet bağlantısını kontrol et.'),
                    TextButton(onPressed: _load, child: const Text('Tekrar dene')),
                  ],
                ),
              )
            else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    _filter == _Filter.active ? 'Aktif kod yok. "Yeni kod" ile oluştur.' : 'Kod yok.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (final c in visible) _tile(c, scheme),
          ],
        ),
      ),
    );
  }

  Widget _tile(_Code c, ColorScheme scheme) {
    final statusColor = c.isUsable ? Colors.green : scheme.outline;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _copy(c.code, '${c.code} kopyalandı'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          c.code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: c.isUsable ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c.status,
                              style: TextStyle(fontSize: 12, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.label.isEmpty ? 'Kime verildiği yazılmamış' : c.label,
                      style: TextStyle(
                        color: c.label.isEmpty ? scheme.outline : null,
                        fontStyle: c.label.isEmpty ? FontStyle.italic : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.max == 0 ? 0 : (c.used / c.max).clamp(0, 1).toDouble(),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.used}/${c.max} kişi kullandı · ${_date(c.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'copy':
                      _copy(c.code, '${c.code} kopyalandı');
                    case 'label':
                      _editLabel(c);
                    case 'close':
                      _deactivate(c);
                    case 'delete':
                      _delete([c], c.code);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'copy', child: Text('Kopyala')),
                  const PopupMenuItem(value: 'label', child: Text('Kime verildi?')),
                  if (c.isUsable) const PopupMenuItem(value: 'close', child: Text('Kapat')),
                  const PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
