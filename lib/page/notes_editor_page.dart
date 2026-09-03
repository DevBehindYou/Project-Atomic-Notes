import 'package:atomic_notes/database/note.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/my_floating_button.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Note editor. Edits the passed [Note] in place and pops `true` when the
/// user saves, `false`/null when they cancel — the caller decides whether to
/// persist, so an abandoned new note never reaches storage.
///
/// Handles both kinds: a body field for text notes, a checklist editor for
/// to-dos, switchable from the header.
class NotesCreaterPage extends StatefulWidget {
  final Note note;

  const NotesCreaterPage({required this.note, super.key});

  @override
  State<NotesCreaterPage> createState() => _NotesCreaterPageState();
}

class _NotesCreaterPageState extends State<NotesCreaterPage> {
  final ScrollController _controller = ScrollController();
  late final TextEditingController _title;
  late final TextEditingController _body;

  /// One controller per checklist row, kept in step with note.items.
  final List<TextEditingController> _itemControllers = [];
  final List<FocusNode> _itemFocus = [];

  Note get note => widget.note;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: note.title);
    _body = TextEditingController(text: note.body);
    for (final i in note.items) {
      _addControllerFor(i.text);
    }
    if (note.kind == NoteKind.todo && note.items.isEmpty) {
      _addRow();
    }
  }

  void _addControllerFor(String text) {
    _itemControllers.add(TextEditingController(text: text));
    _itemFocus.add(FocusNode());
  }

  @override
  void dispose() {
    _controller.dispose();
    _title.dispose();
    _body.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    for (final f in _itemFocus) {
      f.dispose();
    }
    super.dispose();
  }

  // ---- editing ----------------------------------------------------------

  void _addRow({int? after}) {
    setState(() {
      final at = after == null ? note.items.length : after + 1;
      note.items.insert(at, TodoItem(text: ''));
      _itemControllers.insert(at, TextEditingController());
      _itemFocus.insert(at, FocusNode());
    });
    // Focus the row we just created.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final at = after == null ? note.items.length - 1 : after + 1;
      if (at < _itemFocus.length) _itemFocus[at].requestFocus();
    });
  }

  void _removeRow(int i) {
    setState(() {
      note.items.removeAt(i);
      _itemControllers.removeAt(i).dispose();
      _itemFocus.removeAt(i).dispose();
    });
  }

  void _switchKind() {
    setState(() {
      if (note.kind == NoteKind.text) {
        note.kind = NoteKind.todo;
        // Carry the body over as checklist rows rather than losing it.
        final lines = _body.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        note.items = lines.map((l) => TodoItem(text: l)).toList();
        _itemControllers
          ..forEach((c) => c.dispose())
          ..clear();
        _itemFocus
          ..forEach((f) => f.dispose())
          ..clear();
        for (final l in lines) {
          _addControllerFor(l);
        }
        if (note.items.isEmpty) _addRow();
      } else {
        note.kind = NoteKind.text;
        // And back the other way.
        final joined = note.items
            .map((i) => i.text.trim())
            .where((t) => t.isNotEmpty)
            .join('\n');
        if (_body.text.trim().isEmpty) _body.text = joined;
      }
    });
  }

  void _commit() {
    note.title = _title.text;
    if (note.kind == NoteKind.text) {
      note.body = _body.text;
      note.items = [];
    } else {
      for (int i = 0; i < note.items.length; i++) {
        note.items[i].text = _itemControllers[i].text;
      }
      note.items.removeWhere((i) => i.text.trim().isEmpty);
      note.body = '';
    }
  }

  void _save() {
    _commit();
    Navigator.of(context).pop(true);
  }

  void _copy() {
    _commit();
    final text = note.kind == NoteKind.todo
        ? note.items.map((i) => '${i.done ? "[x]" : "[ ]"} ${i.text}').join('\n')
        : note.body;
    Clipboard.setData(ClipboardData(
        text: note.title.trim().isEmpty ? text : '${note.title}\n\n$text'));
    const MySnackBar(text: "Copied to clipboard", sec: 1200)
        .showMySnackBar(context);
  }

  // ---- build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxContentWidth = screenWidth > 600 ? 520.0 : double.infinity;
    final isTodo = note.kind == NoteKind.todo;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Container(
              margin: const EdgeInsets.all(AppSpace.md),
              padding: const EdgeInsets.all(AppSpace.md + 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: AppRadius.std,
                border:
                    Border.all(color: AppColors.ink, width: AppStroke.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MonoLabel(
                            'CREATED ${_stamp(note.createdAt)}'),
                      ),
                      // Kind switch, doubling as the current-kind indicator.
                      GestureDetector(
                        onTap: _switchKind,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTodo
                                  ? Icons.checklist_rounded
                                  : Icons.notes_rounded,
                              size: 14,
                              color: AppColors.signal,
                            ),
                            const SizedBox(width: 4),
                            MonoLabel(isTodo ? 'CHECKLIST' : 'NOTE',
                                color: AppColors.signal),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  const HairRule(color: AppColors.ink),
                  const SizedBox(height: AppSpace.sm),

                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      hintText: "Title",
                      hintStyle: AppType.headlineMd
                          .copyWith(color: AppColors.outlineVariant),
                    ),
                    cursorColor: AppColors.signal,
                    style: AppType.headlineMd,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  const HairRule(),
                  const SizedBox(height: AppSpace.sm),

                  Expanded(
                    child: isTodo ? _checklistEditor() : _bodyEditor(),
                  ),

                  const SizedBox(height: AppSpace.sm),
                  const HairRule(color: AppColors.ink),
                  const SizedBox(height: AppSpace.md),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyFloatingButton(
                        ico: "assets/copy_home.svg",
                        action: _copy,
                        colorValue: 0xff9f5ef7,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyFloatingButton(
                            ico: "assets/cross_circle.svg",
                            action: () => Navigator.of(context).pop(false),
                            colorValue: 0xffa60000,
                          ),
                          const SizedBox(width: AppSpace.sm + 2),
                          MyFloatingButton(
                            ico: "assets/save.svg",
                            action: _save,
                            colorValue: 0xff855ef7,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bodyEditor() {
    return Scrollbar(
      controller: _controller,
      child: TextField(
        controller: _body,
        scrollController: _controller,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: "Start writing…",
          hintStyle: AppType.bodyLg.copyWith(color: AppColors.outline),
        ),
        cursorColor: AppColors.signal,
        style: AppType.bodyLg,
      ),
    );
  }

  Widget _checklistEditor() {
    return Scrollbar(
      controller: _controller,
      child: ListView.builder(
        controller: _controller,
        padding: EdgeInsets.zero,
        itemCount: note.items.length + 1,
        itemBuilder: (context, i) {
          // Trailing "add item" row.
          if (i == note.items.length) {
            return GestureDetector(
              onTap: () => _addRow(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.slateData),
                    SizedBox(width: AppSpace.sm),
                    MonoLabel('ADD ITEM'),
                  ],
                ),
              ),
            );
          }

          final item = note.items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => item.done = !item.done),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        color:
                            item.done ? AppColors.signal : Colors.transparent,
                        border: Border.all(
                          color:
                              item.done ? AppColors.signal : AppColors.outline,
                          width: AppStroke.rule,
                        ),
                      ),
                      child: item.done
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: TextField(
                    controller: _itemControllers[i],
                    focusNode: _itemFocus[i],
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    // Enter starts the next item, like every checklist app.
                    onSubmitted: (_) => _addRow(after: i),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintText: 'List item',
                      hintStyle:
                          AppType.bodyMd.copyWith(color: AppColors.outline),
                    ),
                    cursorColor: AppColors.signal,
                    style: AppType.bodyMd.copyWith(
                      decoration:
                          item.done ? TextDecoration.lineThrough : null,
                      color:
                          item.done ? AppColors.outline : AppColors.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeRow(i),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close,
                        size: 14, color: AppColors.outline),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _stamp(DateTime d) {
    final l = d.toLocal();
    String p(int v) => v.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
  }
}
