import 'package:flutter/material.dart';

class BetaBadge extends StatelessWidget {
  final bool showFloating;
  
  const BetaBadge({
    Key? key,
    this.showFloating = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showFloating) {
      return Positioned(
        top: 50,
        right: 16,
        child: _buildBadge(),
      );
    } else {
      return _buildBadge();
    }
  }

  Widget _buildBadge() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6B35), // Orange
              Color(0xFFE53E3E), // Red
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.science_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'BETA',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

