import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kavaid/services/logger_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final LoggerService _logger = LoggerService();
  String _filter = '';
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoScroll || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Logları'),
        actions: [
          IconButton(
            tooltip: 'Kopyala',
            onPressed: () async {
              final text = _logger.entries
                  .where((e) => _filter.isEmpty || e.toString().toLowerCase().contains(_filter))
                  .map((e) => e.toString())
                  .join('\n');
              await Clipboard.setData(ClipboardData(text: text));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loglar panoya kopyalandı')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'Temizle',
            onPressed: () {
              _logger.clear();
              setState(() {});
            },
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
          IconButton(
            tooltip: _autoScroll ? 'Oto-kaydırmayı kapat' : 'Oto-kaydırmayı aç',
            onPressed: () {
              setState(() => _autoScroll = !_autoScroll);
            },
            icon: Icon(_autoScroll ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filtrele (metin arayın)...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filter = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LogEntry>>(
              stream: _logger.stream,
              initialData: _logger.entries,
              builder: (context, snapshot) {
                final items = (snapshot.data ?? const <LogEntry>[]) 
                    .where((e) => _filter.isEmpty || e.toString().toLowerCase().contains(_filter))
                    .toList();
                _scrollToEnd();
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final e = items[index];
                    Color stripe;
                    switch (e.level) {
                      case 'warn': stripe = Colors.amber; break;
                      case 'error': stripe = Colors.redAccent; break;
                      default: stripe = Colors.blueAccent;
                    }
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: stripe, width: 3),
                          bottom: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA), width: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(
                        e.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: e.level == 'error' ? Colors.red[300] : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
