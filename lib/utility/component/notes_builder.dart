import 'package:atomic_notes/database/note.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:flutter/material.dart';

/// A note card. Renders either a text note or a checklist, and doubles as the
/// selection target in multi-select mode.
///
/// Long-press enters selection; the Slidable swipe-to-delete it used to carry
/// is gone, replaced by multi-select, which handles one note and twenty the
/// same way.
class NotesBulder extends StatelessWidget {
  final Note note;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Ticking a checklist row straight from the card.
  final void Function(int index) onToggleItem;

  const NotesBulder({
    required this.note,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool untitled = note.title.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md - 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: AppRadius.std,
            border: Border.all(
              color: selected ? AppColors.signal : AppColors.outlineVariant,
              width: selected ? AppStroke.offset : AppStroke.rule,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MonoLabel(_stamp(note.createdAt), small: true),
                  ),
                  if (selectionMode)
                    _Tick(on: selected)
                  else if (note.kind == NoteKind.todo)
                    MonoLabel(
                      '${note.doneCount}/${note.items.length}',
                      small: true,
                      color: note.items.isNotEmpty &&
                              note.doneCount == note.items.length
                          ? AppColors.signal
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              const HairRule(),
              const SizedBox(height: AppSpace.sm),
              EditorialHeading(
                untitled ? 'Untitled' : note.title,
                style: AppType.headlineSm.copyWith(
                  color: untitled ? AppColors.outline : AppColors.ink,
                ),
                maxLines: 2,
              ),
              if (note.kind == NoteKind.todo)
                _checklist()
              else if (note.body.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs + 2),
                Text(
                  note.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodySm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _checklist() {
    final rows = note.items.take(4).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                // In selection mode the whole card is the target, so don't
                // let a tick steal the tap.
                onTap: selectionMode ? null : () => onToggleItem(i),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Tick(on: rows[i].done, small: true),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        rows[i].text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.bodySm.copyWith(
                          decoration: rows[i].done
                              ? TextDecoration.lineThrough
                              : null,
                          color: rows[i].done
                              ? AppColors.outline
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (note.items.length > rows.length)
            MonoLabel('+${note.items.length - rows.length} MORE', small: true),
        ],
      ),
    );
  }

  /// Trims the stored ISO stamp down to "YYYY-MM-DD HH:MM" for the card.
  static String _stamp(DateTime d) {
    final l = d.toLocal();
    String p(int v) => v.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
  }
}

/// Square checkbox — the design system calls for 0-radius controls, and a
/// solid Signal block for the checked state.
class _Tick extends StatelessWidget {
  final bool on;
  final bool small;
  const _Tick({required this.on, this.small = false});

  @override
  Widget build(BuildContext context) {
    final s = small ? 14.0 : 18.0;
    return Container(
      height: s,
      width: s,
      decoration: BoxDecoration(
        color: on ? AppColors.signal : Colors.transparent,
        border: Border.all(
          color: on ? AppColors.signal : AppColors.outline,
          width: AppStroke.rule,
        ),
      ),
      child: on
          ? Icon(Icons.check, size: s - 4, color: Colors.white)
          : null,
    );
  }
}
