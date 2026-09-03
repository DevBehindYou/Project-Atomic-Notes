// Tests for the leaf components and the note model — the parts that don't
// need Supabase or Hive to be initialised. (Pumping MyApp itself isn't
// possible in a plain widget test: main() must initialise Supabase and open
// the Hive boxes first.)

import 'package:atomic_notes/database/note.dart';
import 'package:atomic_notes/database/note_quota.dart';
import 'package:atomic_notes/utility/component/my_textfield.dart';
import 'package:atomic_notes/utility/component/notes_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _card(
  Note note, {
  bool selected = false,
  bool selectionMode = false,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  void Function(int)? onToggleItem,
}) =>
    _wrap(NotesBulder(
      note: note,
      selected: selected,
      selectionMode: selectionMode,
      onTap: onTap ?? () {},
      onLongPress: onLongPress ?? () {},
      onToggleItem: onToggleItem ?? (_) {},
    ));

void main() {
  group('MyTextField', () {
    testWidgets('masks input when obscureText is set', (tester) async {
      await tester.pumpWidget(_wrap(MyTextField(
        ico: const Icon(Icons.password),
        hintText: 'Enter Password',
        controller: TextEditingController(),
        obscureText: true,
      )));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      // Keyboard learning must stay off for secrets.
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
    });

    testWidgets('shows input in the clear by default', (tester) async {
      await tester.pumpWidget(_wrap(MyTextField(
        ico: const Icon(Icons.email),
        hintText: 'Enter Email',
        controller: TextEditingController(),
      )));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
    });
  });

  group('Note model', () {
    test('ids are unique and RFC 4122 v4 shaped', () {
      final ids = List.generate(200, (_) => newId());
      expect(ids.toSet().length, 200);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(ids.first),
        isTrue,
        reason: 'got ${ids.first}',
      );
    });

    test('survives a round trip through the local map form', () {
      final a = Note.create(kind: NoteKind.todo)
        ..title = 'Shopping'
        ..items = [TodoItem(text: 'milk', done: true), TodoItem(text: 'bread')];

      final b = Note.fromMap(a.toMap());
      expect(b.id, a.id);
      expect(b.kind, NoteKind.todo);
      expect(b.title, 'Shopping');
      expect(b.items.length, 2);
      expect(b.items.first.done, isTrue);
      expect(b.items.last.text, 'bread');
    });

    test('a note read back from the server is not dirty', () {
      final n = Note.fromRemote({
        'id': '11111111-1111-4111-8111-111111111111',
        'kind': 'text',
        'title': 'x',
        'body': 'y',
        'items': [],
        'pinned': false,
        'deleted': false,
        'created_at': '2026-07-28T10:00:00Z',
        'updated_at': '2026-07-28T10:00:00Z',
      });
      expect(n.dirty, isFalse);
      expect(n.updatedAt.isUtc, isTrue);
    });

    test('toRemote omits updated_at so the server trigger owns it', () {
      final n = Note.create()..title = 'a';
      expect(n.toRemote('user-1').containsKey('updated_at'), isFalse);
      expect(n.toRemote('user-1')['user_id'], 'user-1');
    });

    test('the dirty flag survives a restart', () {
      // A note written offline must still be dirty after the app is killed
      // and reopened, or the next push would skip it and the note would never
      // reach the server. (An earlier version of this test wrongly assumed a
      // round trip cleared the flag.)
      final created = Note.create()..title = 'written on a plane';
      expect(created.dirty, isTrue);
      expect(Note.fromMap(created.toMap()).dirty, isTrue);
    });

    test('touch marks dirty and moves updatedAt forward', () async {
      // Start from a server copy, which is clean by definition.
      final n = Note.fromRemote({
        'id': '22222222-2222-4222-8222-222222222222',
        'kind': 'text',
        'title': 'x',
        'body': '',
        'items': [],
        'pinned': false,
        'deleted': false,
        'created_at': '2026-07-28T10:00:00Z',
        'updated_at': '2026-07-28T10:00:00Z',
      });
      expect(n.dirty, isFalse);

      final before = n.updatedAt;
      n.touch();
      expect(n.dirty, isTrue);
      expect(n.updatedAt.isAfter(before), isTrue);
    });

    test('the free allowance is 20, shared by notes and to-dos', () {
      // The cap is a stored value so the future coin system can raise it
      // without a release; 50 is only the default.
      expect(NoteQuota.freeLimit, 20);
    });

    test('isEmpty ignores whitespace-only content', () {
      expect((Note.create()..title = '  ').isEmpty, isTrue);
      expect((Note.create()..body = 'x').isEmpty, isFalse);
      expect(
        (Note.create(kind: NoteKind.todo)..items = [TodoItem(text: '  ')])
            .isEmpty,
        isTrue,
      );
    });
  });

  group('NotesBulder', () {
    // The Technical Editorial system sets headings and metadata in uppercase
    // (Bebas Neue / JetBrains Mono), so these assertions lock that in.
    testWidgets('renders a text note', (tester) async {
      final note = Note.create()
        ..title = 'Shopping list'
        ..body = 'milk, bread';
      await tester.pumpWidget(_card(note));

      expect(find.text('SHOPPING LIST'), findsOneWidget);
      // Body copy is never case-transformed.
      expect(find.text('milk, bread'), findsOneWidget);
    });

    testWidgets('falls back to "Untitled" when the title is blank',
        (tester) async {
      await tester.pumpWidget(_card(Note.create()..body = 'body only'));
      expect(find.text('UNTITLED'), findsOneWidget);
    });

    testWidgets('shows checklist rows and a done count', (tester) async {
      final note = Note.create(kind: NoteKind.todo)
        ..title = 'Trip'
        ..items = [
          TodoItem(text: 'passport', done: true),
          TodoItem(text: 'tickets'),
        ];
      await tester.pumpWidget(_card(note));

      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('passport'), findsOneWidget);
      expect(find.text('tickets'), findsOneWidget);
    });

    testWidgets('ticking a checklist row reports its index', (tester) async {
      int? toggled;
      final note = Note.create(kind: NoteKind.todo)
        ..items = [TodoItem(text: 'first'), TodoItem(text: 'second')];
      await tester.pumpWidget(_card(note, onToggleItem: (i) => toggled = i));

      await tester.tap(find.text('second'));
      expect(toggled, 1);
    });

    testWidgets('tap and long-press drive selection', (tester) async {
      var tapped = false;
      var held = false;
      final note = Note.create()..title = 'Tap me';
      await tester.pumpWidget(_card(
        note,
        onTap: () => tapped = true,
        onLongPress: () => held = true,
      ));

      await tester.tap(find.text('TAP ME'));
      expect(tapped, isTrue);

      await tester.longPress(find.text('TAP ME'));
      expect(held, isTrue);
    });
  });
}
