import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ArgusButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ArgusButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ArgusColors.green,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        '<<$label>>',
        style: const TextStyle(
          fontSize: 16,
          letterSpacing: 2,
        ),
      ),
    );
  }
}