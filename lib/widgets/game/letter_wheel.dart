import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kelime oyununun harf çarkı. Harfler bir daire üzerinde durur; oyuncu parmağını kaldırmadan
/// harften harfe sürükleyerek ya da harflere tek tek dokunarak kelimeyi kurar.
///
/// Seçim [selected] listesinde tutulur ve sahibi onu yerinde değiştirir (aynı liste nesnesi):
/// iki dokunma olayı arasında ekran yeniden çizilmese de çark güncel seçimi görür.
class LetterWheel extends StatefulWidget {
  const LetterWheel({
    super.key,
    required this.letters,
    required this.selected,
    required this.size,
    required this.accent,
    required this.onAdd,
    required this.onRemoveLast,
    required this.onEnd,
    this.onMiss,
    this.enabled = true,
    this.error = false,
  });

  final List<String> letters;
  final List<int> selected;
  final double size;
  final Color accent;
  final bool enabled;

  /// Yanlış kelime: seçim kırmızı gösterilir.
  final bool error;

  final ValueChanged<int> onAdd;
  final VoidCallback onRemoveLast;

  /// Parmak kalktı. [swiped]: bu dokunuşta sürükleyerek en az iki harf eklendi.
  final ValueChanged<bool> onEnd;

  /// Hiçbir harfe değmeyen dokunuş (çarkın boş yeri): seçimi bırakmak için.
  final VoidCallback? onMiss;

  static double tileRadius(double size) => size * 0.118;

  /// [index]. harfin çark içindeki merkezi (çarkın sol üst köşesine göre).
  static Offset centerOf(int index, int count, double size) {
    final ring = size / 2 - tileRadius(size) - size * 0.045;
    final angle = 2 * math.pi * index / count - math.pi / 2;
    return Offset(size / 2 + ring * math.cos(angle), size / 2 + ring * math.sin(angle));
  }

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel> {
  int? _pointer;
  Offset? _drag;
  int _added = 0;
  bool _undoLast = false;
  bool _touched = false;

  List<Offset> get _centers => [
    for (var i = 0; i < widget.letters.length; i++)
      LetterWheel.centerOf(i, widget.letters.length, widget.size),
  ];

  int? _hit(Offset p) {
    final centers = _centers;
    final tile = LetterWheel.tileRadius(widget.size);
    // Dokunma alanı harfin dairesinden biraz küçük: bir harfi atlayıp ötekine sürüklerken
    // aradaki harf seçilmesin (7 harfli çarkta atlanan harfin merkezi yola ~35 px uzaklıkta).
    final gap = centers.length > 1 ? (centers[0] - centers[1]).distance / 2 - 1 : tile;
    final reach = math.min(tile * 0.92, gap);
    for (var i = 0; i < centers.length; i++) {
      if ((centers[i] - p).distance <= reach) return i;
    }
    return null;
  }

  void _down(PointerDownEvent e) {
    if (!widget.enabled || _pointer != null) return;
    _pointer = e.pointer;
    _added = 0;
    _undoLast = false;
    final i = _hit(e.localPosition);
    _touched = i != null;
    if (i != null) {
      if (!widget.selected.contains(i)) {
        _add(i);
      } else if (widget.selected.last == i) {
        _undoLast = true; // seçili son harfe yeniden dokunmak onu geri alır
      }
    }
    setState(() => _drag = e.localPosition);
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final i = _hit(e.localPosition);
    if (i != null) {
      _touched = true;
      final sel = widget.selected;
      if (!sel.contains(i)) {
        _add(i);
        _undoLast = false;
      } else if (_added > 0 && sel.length >= 2 && sel[sel.length - 2] == i) {
        // Bir önceki harfe geri dönmek son harfi bırakır.
        widget.onRemoveLast();
        _added--;
      }
    }
    setState(() => _drag = e.localPosition);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    setState(() => _drag = null);
    if (!_touched) {
      widget.onMiss?.call();
      return;
    }
    if (_undoLast && _added == 0) widget.onRemoveLast();
    widget.onEnd(_added >= 2);
  }

  void _add(int i) {
    HapticFeedback.selectionClick();
    widget.onAdd(i);
    _added++;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final tile = LetterWheel.tileRadius(size);
    final centers = _centers;
    final color = widget.error ? const Color(0xFFFF3B30) : widget.accent;
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1C1C1E);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.94),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _PathPainter(
                  points: [for (final i in widget.selected) centers[i]],
                  drag: _drag,
                  color: color,
                  width: tile * 0.42,
                ),
              ),
            ),
            for (var i = 0; i < centers.length; i++)
              Positioned(
                left: centers[i].dx - tile,
                top: centers[i].dy - tile,
                width: tile * 2,
                height: tile * 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.selected.contains(i) ? color : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.letters[i],
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: tile * 1.2,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: widget.selected.contains(i) ? onColor : const Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.points, required this.drag, required this.color, required this.width});

  final List<Offset> points;
  final Offset? drag;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (drag != null) path.lineTo(drag!.dx, drag!.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.drag != drag || old.color != color || old.width != width || !listEquals(old.points, points);
}
