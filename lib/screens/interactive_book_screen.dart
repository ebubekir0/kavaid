import 'package:flutter/material.dart';

class InteractiveBookScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final String arabicTitle;
  final String thumbnail;

  const InteractiveBookScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.arabicTitle,
    required this.thumbnail,
  });

  @override
  State<InteractiveBookScreen> createState() => _InteractiveBookScreenState();
}

class _InteractiveBookScreenState extends State<InteractiveBookScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
      ),
      body: const Center(
        child: Text('Kitap içeriği hazırlanıyor...'),
      ),
    );
  }
}
