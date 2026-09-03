// ignore_for_file: camel_case_types

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Thin Signal-coloured spinner. Deliberately light-weight: in this system a
/// busy state is a hairline detail, not a heavy Material ring.
class circularProgress extends StatelessWidget {
  const circularProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.signal,
          backgroundColor: AppColors.surfaceHighest,
        ),
      ),
    );
  }
}
