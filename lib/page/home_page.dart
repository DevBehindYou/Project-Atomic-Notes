// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:atomic_notes/database/note.dart';
import 'package:atomic_notes/database/notes_repository.dart';
import 'package:atomic_notes/page/notes_editor_page.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/note_skeliton.dart';
import 'package:atomic_notes/utility/component/notes_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotesRepository repo = NotesRepository.instance;
  final ScrollController _controller = ScrollController();

  NoteFilter _filter = NoteFilter.newest;

  /// Live text search over the current account's notes (title, body, checklist
  /// items). Runs entirely in memory on the already-decrypted notes, so it never
  /// touches the network and works offline.
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  /// Ids picked in multi-select mode. Empty means normal browsing.
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    repo.removeListener(_onRepoChanged);
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    setState(() {
      // Drop selections for notes that vanished under us (deleted on another
      // device, or pulled in as a tombstone).
      _selected.removeWhere((id) => repo.byId(id)?.deleted ?? true);
    });
  }

  // ---- actions ----------------------------------------------------------

  void _openEditor(Note note, {required bool isNew}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NotesCreaterPage(note: note),
    );
    if (saved == true) {
      if (note.isEmpty) {
        if (!mounted) return;
        const MySnackBar(text: "Empty note discarded", sec: 1200)
            .showMySnackBar(context);
        return;
      }
      await repo.save(note);
    } else if (isNew) {
      // Nothing to do — an abandoned new note was never stored.
    }
  }

  void _newNote(NoteKind kind) {
    // Notes and to-dos draw on the same allowance.
    if (repo.isAtLimit) {
      MySnackBar(
        text: "You've reached ${repo.limit} notes — delete one to make room",
        sec: 3000,
      ).showMySnackBar(context);
      return;
    }
    _openEditor(Note.create(kind: kind), isNew: true);
  }

  void _toggleSelect(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _deleteSelected() async {
    final n = _selected.length;
    await repo.deleteNotes(_selected.toList());
    if (!mounted) return;
    setState(_selected.clear);
    MySnackBar(
      text: n == 1 ? "Note deleted" : "$n notes deleted",
      sec: 1500,
    ).showMySnackBar(context);
  }

  void _selectAll(List<Note> shown) {
    setState(() {
      if (_selected.length == shown.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(shown.map((n) => n.id));
      }
    });
  }

  int _responsiveColumnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 5;
    if (width >= 800) return 4;
    if (width >= 550) return 3;
    return 2;
  }

  // ---- build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final all = repo.visible(filter: _filter);
    final q = _query.trim().toLowerCase();
    final notes = q.isEmpty
        ? all
        : all
            .where((n) =>
                n.title.toLowerCase().contains(q) ||
                n.body.toLowerCase().contains(q) ||
                n.items.any((it) => it.text.toLowerCase().contains(q)))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(notes),
          Expanded(
            child: notes.isEmpty
                ? _emptyState()
                : Scrollbar(
                    radius: AppRadius.smRadius,
                    thickness: 4,
                    controller: _controller,
                    child: MasonryGridView.count(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.md, AppSpace.sm, AppSpace.md, 110),
                      crossAxisCount: _responsiveColumnCount(context),
                      mainAxisSpacing: AppSpace.sm,
                      crossAxisSpacing: AppSpace.sm,
                      controller: _controller,
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return NotesBulder(
                          key: ValueKey(note.id),
                          note: note,
                          selected: _selected.contains(note.id),
                          selectionMode: _selecting,
                          onTap: () => _selecting
                              ? _toggleSelect(note.id)
                              : _openEditor(note, isNew: false),
                          onLongPress: () => _toggleSelect(note.id),
                          onToggleItem: (i) async {
                            note.items[i].done = !note.items[i].done;
                            await repo.save(note);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _selecting ? null : _addMenu(),
    );
  }

  Widget _header(List<Note> notes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.md, AppSpace.md, AppSpace.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: EditorialHeading(
                  _selecting ? '${_selected.length} selected' : 'Notes',
                  style: AppType.headlineLg,
                  maxLines: 1,
                ),
              ),
              if (_selecting) ...[
                GestureDetector(
                  onTap: () => _selectAll(notes),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    child: MonoLabel('ALL'),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(_selected.clear),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    child: MonoLabel('CANCEL'),
                  ),
                ),
                GestureDetector(
                  onTap: _deleteSelected,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm + 2, vertical: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      borderRadius: AppRadius.std,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline,
                            size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        MonoLabel('DELETE', color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ] else
                // Usage is shown always, not just when it's a problem, so
                // running out is never a surprise.
                MonoLabel(
                  '${repo.usageLabel}'
                  '${repo.pendingCount > 0 ? " · ${repo.pendingCount} UNSYNCED" : ""}',
                  color: repo.isAtLimit
                      ? AppColors.error
                      : (repo.remaining <= 5 ? AppColors.signal : null),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const HairRule(color: AppColors.ink),
          if (!_selecting) ...[
            const SizedBox(height: AppSpace.sm),
            // Filter / sort row.
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: NoteFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpace.xs + 2),
                itemBuilder: (context, i) {
                  final f = NoteFilter.values[i];
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    behavior: HitTestBehavior.opaque,
                    child: DataChip(f.label, active: _filter == f),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            _searchField(),
          ],
        ],
      ),
    );
  }

  /// Live search field under the filter chips.
  Widget _searchField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.outlineVariant, width: AppStroke.rule),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.slateData),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: AppColors.signal,
              style: AppType.bodyMd,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search notes',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: AppColors.slateData),
              ),
            ),
        ],
      ),
    );
  }

  /// Two-way add: a plain note or a checklist. Both dim at the cap.
  Widget _addMenu() {
    final full = repo.isAtLimit;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (full)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpace.sm),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm + 2, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: AppRadius.std,
              border: Border.all(color: AppColors.error, width: AppStroke.rule),
            ),
            child: MonoLabel('${repo.limit} NOTE LIMIT REACHED',
                color: AppColors.onErrorContainer),
          ),
        GestureDetector(
          onTap: () => _newNote(NoteKind.todo),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: AppRadius.std,
              border:
                  Border.all(color: AppColors.ink, width: AppStroke.hairline),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist_rounded, size: 16, color: AppColors.ink),
                SizedBox(width: AppSpace.sm),
                MonoLabel('CHECKLIST', color: AppColors.ink),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        GestureDetector(
          onTap: () => _newNote(NoteKind.text),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: AppRadius.std,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(AppStroke.offset, AppStroke.offset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md + 2, vertical: AppSpace.md - 2),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: AppRadius.std,
                border: Border.all(
                    color: AppColors.ink, width: AppStroke.hairline),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: AppColors.paper),
                  SizedBox(width: AppSpace.sm),
                  MonoLabel('NEW NOTE', color: AppColors.paper),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    final filtered = _filter == NoteFilter.todos ||
        _filter == NoteFilter.notes ||
        _query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel(filtered ? 'FILTER / NO MATCH' : 'INDEX / EMPTY'),
            const SizedBox(height: AppSpace.sm),
            EditorialHeading(
              filtered ? 'Nothing here\nyet.' : 'Nothing written\nyet.',
              style: AppType.headlineLg,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              filtered
                  ? 'No notes match this filter. Try another one.'
                  : 'Tap New note to start writing, or Checklist for '
                      'something you can tick off.',
              style: AppType.bodyMd.copyWith(color: AppColors.slateData),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kept so existing imports of the skeleton keep resolving.
const Widget kNotesSkeleton = Skeliton();
