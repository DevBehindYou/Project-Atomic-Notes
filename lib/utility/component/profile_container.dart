import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:flutter/material.dart';

/// Account module on the settings screen: avatar framed in an Ink block on the
/// left, session metadata and the logout action on the right.
///
/// Replaces the old fixed 180px photo + 120px button row that could overflow
/// on narrow phones — this lays out fluidly at any width.
class ProConatainer extends StatelessWidget {
  final bool isLoading;
  final VoidCallback logout;
  const ProConatainer({
    super.key,
    required this.isLoading,
    required this.logout,
  });

  @override
  Widget build(BuildContext context) {
    return EditorialModule(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar in an Ink frame, matching how the logo mark is treated.
              Container(
                height: 64,
                width: 64,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: AppRadius.std,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.sm,
                  child: Image.asset('assets/photo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoLabel('SESSION / ACTIVE', color: AppColors.signal),
                    SizedBox(height: AppSpace.xs),
                    EditorialHeading('Signed in',
                        style: AppType.headlineSm, maxLines: 1),
                    SizedBox(height: 2),
                    Text(
                      'Notes stay on this device until you sync.',
                      style: AppType.bodySm,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          GhostButton(
            label: isLoading ? 'Signing out…' : 'Log out',
            icon: Icons.logout,
            onTap: isLoading ? null : logout,
          ),
        ],
      ),
    );
  }
}
