import 'package:flutter/material.dart';
import '../models/person.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;

  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
  });

  Widget _buildFallbackAvatar() {
    if (person.emoji.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade200,
        child: Center(
          child: Text(
            person.emoji,
            style: const TextStyle(fontSize: 50),
          ),
        ),
      );
    }
    
    final emojis = [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', 
      '🦁', '🐮', '🐷', '🐸', '🐵', '🐧', '🦉', '🦄', '🐝', '🐛', 
      '🦋', '🐌', '🐞', '🐜', '🐢', '🐙', '🦑', '🐠', '🐟', '🐬'
    ];
    int index = 0;
    if (person.name.isNotEmpty) {
      index = person.name.codeUnits.fold<int>(0, (a, b) => a + b) % emojis.length;
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          emojis[index],
          style: const TextStyle(fontSize: 50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (person.avatarUrl.isNotEmpty)
                Image.network(
                  person.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackAvatar();
                  },
                )
              else
                _buildFallbackAvatar(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
                padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${person.wishlist.length} items',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }
}
