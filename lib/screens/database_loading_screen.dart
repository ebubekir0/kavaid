import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/app_startup_service.dart';

class DatabaseLoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;

  const DatabaseLoadingScreen({super.key, required this.onLoadingComplete});

  @override
  State<DatabaseLoadingScreen> createState() => _DatabaseLoadingScreenState();
}

class _DatabaseLoadingScreenState extends State<DatabaseLoadingScreen> {
  final AppStartupService _startup = AppStartupService.instance;
  bool _started = false;

  String _l(String tr, String en, String ar) {
    return tr;
  }

  String get _textRetry => _l('Tekrar Dene', 'Retry', 'اعادة المحاولة');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _startup.addListener(_onStartupChanged);
    _startup.start(context: context);
  }

  @override
  void dispose() {
    _startup.removeListener(_onStartupChanged);
    super.dispose();
  }

  void _onStartupChanged() {
    if (!mounted) return;
    if (_startup.isReady) {
      widget.onLoadingComplete();
      return;
    }
    setState(() {});
  }

  void _retry() {
    _startup.retry(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _startup.phase == StartupPhase.recoverableError;
    final progress = _startup.progress.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _startup.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!hasError) ...[
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE5E5EA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF007AFF),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF3B30),
                  size: 36,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _textRetry,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
