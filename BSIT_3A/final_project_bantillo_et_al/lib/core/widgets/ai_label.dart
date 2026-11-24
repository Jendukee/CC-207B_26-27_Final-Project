// "AI-generated" badge. Put it next to every message or text that came
// from the Gemini-powered assistant so users know it is not from staff.
//
// OWNER: team lead. Change only via a reviewed PR.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';

/// Small badge that marks content as AI-generated.
class AiLabel extends StatelessWidget {
  /// Creates the badge.
  const AiLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI-generated content',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.goldTint,
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // UI audit #39: maroon icon (gold on the gold tint was below
            // 3:1); the text label carries the meaning.
            Icon(Icons.auto_awesome, size: 16, color: AppColors.maroon),
            SizedBox(width: 4),
            Text(
              'AI-generated',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
