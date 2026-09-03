import 'dart:math';

/// A note.
///
/// Replaces the old `[title, body, when]` three-element list, which had no id,
/// no type and no modification time — so there was nothing to check off,
/// nothing to filter on, nothing to select, and nothing to merge between
/// devices.
///
/// Ids are generated on the client so a note has a stable identity from the
/// moment it is created, before it has ever reached the server.
enum NoteKind { text, todo }

class TodoItem {
  String text;
  bool done;

  TodoItem({required this.text, this.done = false});

  Map<String, dynamic> toMap() => {'t': text, 'd': done};

  factory TodoItem.fromMap(Map<dynamic, dynamic> m) => TodoItem(
        text: (m['t'] ?? '').toString(),
        done: m['d'] == true,
      );

  TodoItem copy() => TodoItem(text: text, done: done);
}

class Note {
  final String id;
  NoteKind kind;
  String title;
  String body;
  List<TodoItem> items;
  bool pinned;

  /// Tombstone. Deleting sets this rather than dropping the record: without a
  /// tombstone, a delete on one device can never reach another device, which
  /// would simply re-upload the copy it still holds.
  bool deleted;

  DateTime createdAt;

  /// Server-authoritative once synced — Postgres sets it via trigger, so a
  /// device with a wrong clock can't win a conflict with a future timestamp.
  DateTime updatedAt;

  /// Local-only: this note has changes that haven't been pushed yet.
  bool dirty;

  Note({
    required this.id,
    this.kind = NoteKind.text,
    this.title = '',
    this.body = '',
    List<TodoItem>? items,
    this.pinned = false,
    this.deleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.dirty = false,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  factory Note.create({NoteKind kind = NoteKind.text}) =>
      Note(id: newId(), kind: kind, dirty: true);

  /// True when the note holds nothing worth keeping.
  bool get isEmpty =>
      title.trim().isEmpty &&
      body.trim().isEmpty &&
      items.every((i) => i.text.trim().isEmpty);

  int get doneCount => items.where((i) => i.done).length;

  /// One-line preview for the card.
  String get preview {
    if (kind == NoteKind.todo) {
      return items
          .where((i) => i.text.trim().isNotEmpty)
          .map((i) => i.text)
          .join(', ');
    }
    return body;
  }

  void touch() {
    updatedAt = DateTime.now().toUtc();
    dirty = true;
  }

  // ---- Hive (local) ----------------------------------------------------
  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'body': body,
        'items': items.map((i) => i.toMap()).toList(),
        'pinned': pinned,
        'deleted': deleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'dirty': dirty,
      };

  factory Note.fromMap(Map<dynamic, dynamic> m) => Note(
        id: (m['id'] ?? newId()).toString(),
        kind: (m['kind'] ?? 'text') == 'todo' ? NoteKind.todo : NoteKind.text,
        title: (m['title'] ?? '').toString(),
        body: (m['body'] ?? '').toString(),
        items: ((m['items'] as List?) ?? const [])
            .whereType<Map>()
            .map(TodoItem.fromMap)
            .toList(),
        pinned: m['pinned'] == true,
        deleted: m['deleted'] == true,
        createdAt: _parseDate(m['createdAt']),
        updatedAt: _parseDate(m['updatedAt']),
        dirty: m['dirty'] == true,
      );

  // ---- Supabase (remote) -----------------------------------------------
  /// `updated_at` is intentionally omitted — the server trigger owns it.
  Map<String, dynamic> toRemote(String userId) => {
        'id': id,
        'user_id': userId,
        'kind': kind.name,
        'title': title,
        'body': body,
        'items': items.map((i) => i.toMap()).toList(),
        'pinned': pinned,
        'deleted': deleted,
        'created_at': createdAt.toIso8601String(),
      };

  factory Note.fromRemote(Map<dynamic, dynamic> m) => Note(
        id: m['id'].toString(),
        kind: (m['kind'] ?? 'text') == 'todo' ? NoteKind.todo : NoteKind.text,
        title: (m['title'] ?? '').toString(),
        body: (m['body'] ?? '').toString(),
        items: _decodeItems(m['items']),
        pinned: m['pinned'] == true,
        deleted: m['deleted'] == true,
        createdAt: _parseDate(m['created_at']),
        updatedAt: _parseDate(m['updated_at']),
        // Anything from the server is by definition already pushed.
        dirty: false,
      );

  static List<TodoItem> _decodeItems(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map(TodoItem.fromMap).toList();
    }
    return [];
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v.toUtc();
    if (v is String) {
      return DateTime.tryParse(v)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }

  Note copy() => Note(
        id: id,
        kind: kind,
        title: title,
        body: body,
        items: items.map((i) => i.copy()).toList(),
        pinned: pinned,
        deleted: deleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
        dirty: dirty,
      );
}

/// RFC 4122 v4. Written out rather than pulling in the `uuid` package for
/// fifteen lines of work.
String newId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 10
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = StringBuffer();
  for (int i = 0; i < 16; i++) {
    if (i == 4 || i == 6 || i == 8 || i == 10) s.write('-');
    s.write(h(i));
  }
  return s.toString();
}

/// How the notes list is ordered / narrowed on the home screen.
enum NoteFilter { newest, oldest, todos, notes }

extension NoteFilterLabel on NoteFilter {
  String get label => switch (this) {
        NoteFilter.newest => 'Newest',
        NoteFilter.oldest => 'Oldest',
        NoteFilter.todos => 'To-dos',
        NoteFilter.notes => 'Notes',
      };
}
