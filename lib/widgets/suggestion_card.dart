import 'package:flutter/material.dart';
import '../models/word_model.dart';

class SuggestionCard extends StatelessWidget {
  final WordModel word;
  final VoidCallback onTap;

  const SuggestionCard({
    super.key,
    required this.word,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.kelime,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    if (word.harekeliKelime?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        word.harekeliKelime!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8E8E93),
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                    if (word.anlam?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        (word.anlam!.length > 60) 
                            ? '${word.anlam!.substring(0, 60)}...'
                            : word.anlam!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFD1D1D6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 