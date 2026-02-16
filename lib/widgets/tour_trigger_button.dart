import 'package:flutter/material.dart';

class TourTriggerButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool showBadge;

  const TourTriggerButton({
    Key? key,
    required this.onPressed,
    this.showBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: onPressed,
          tooltip: 'App Tour',
          iconSize: 28,
        ),
        if (showBadge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}