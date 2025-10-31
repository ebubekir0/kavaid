import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../utils/performance_utils.dart';

/// 🚀 PERFORMANCE MOD: Gerçek zamanlı FPS sayacı widget'i
class FPSCounterWidget extends StatefulWidget {
  final bool showDetailed;
  
  const FPSCounterWidget({
    super.key,
    this.showDetailed = false,
  });

  @override
  State<FPSCounterWidget> createState() => _FPSCounterWidgetState();
}

class _FPSCounterWidgetState extends State<FPSCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _currentFPS = 0.0;
  int _frameCount = 0;
  DateTime _lastUpdate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // FPS izlemeyi başlat
    _startFPSTracking();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _startFPSTracking() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_lastUpdate).inMilliseconds;
      
      // Her 500ms'de bir FPS'i güncelle
      if (elapsed >= 500) {
        final fps = (_frameCount * 1000) / elapsed;
        setState(() {
          _currentFPS = fps;
        });
        _frameCount = 0;
        _lastUpdate = now;
      }
      
      // Sürekli frame tracking
      if (mounted) {
        _startFPSTracking();
      }
    });
  }
  
  Color _getFPSColor() {
    if (_currentFPS >= 55) return Colors.green;
    if (_currentFPS >= 35) return Colors.orange;
    return Colors.red;
  }
  
  String _getFPSText() {
    if (_currentFPS == 0) return 'FPS: --';
    return 'FPS: ${_currentFPS.toStringAsFixed(0)}';
  }
  
  @override
  Widget build(BuildContext context) {
    final fpsColor = _getFPSColor();
    final performanceCategory = PerformanceUtils.deviceCategory;
    final dropRate = PerformanceUtils.dropRate;
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fpsColor, width: 2),
        ),
        child: widget.showDetailed ? _buildDetailedView(fpsColor) : _buildSimpleView(fpsColor),
      ),
    );
  }
  
  Widget _buildSimpleView(Color fpsColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.speed,
          color: fpsColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          _getFPSText(),
          style: TextStyle(
            color: fpsColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailedView(Color fpsColor) {
    final performanceCategory = PerformanceUtils.deviceCategory;
    final dropRate = PerformanceUtils.dropRate;
    final totalFrames = PerformanceUtils.totalFrames;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // FPS satırı
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              color: fpsColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _getFPSText(),
              style: TextStyle(
                color: fpsColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Cihaz kategorisi
        Text(
          'Device: $performanceCategory',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        
        // Drop rate (eğer 0'dan büyükse)
        if (dropRate > 0) ...[
          const SizedBox(height: 2),
          Text(
            'Drop: ${dropRate.toStringAsFixed(1)}%',
            style: TextStyle(
              color: dropRate > 5 ? Colors.red : Colors.yellow,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
        
        // Frame sayısı
        if (totalFrames > 0) ...[
          const SizedBox(height: 2),
          Text(
            'Frames: $totalFrames',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }
}

/// 🚀 PERFORMANCE MOD: FPS overlay gösterici
class FPSOverlay extends StatelessWidget {
  final Widget child;
  final bool showFPS;
  final bool detailedFPS;
  
  const FPSOverlay({
    super.key,
    required this.child,
    this.showFPS = false,
    this.detailedFPS = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!showFPS) return child;
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          FPSCounterWidget(showDetailed: detailedFPS),
        ],
      ),
    );
  }
} 