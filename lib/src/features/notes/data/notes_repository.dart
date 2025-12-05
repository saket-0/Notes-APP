import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/src/core/database/app_database.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(databaseProvider));
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

class NotesRepository {
  final AppDatabase _db;

  NotesRepository(this._db);

  // --- Folder Operations ---
  Stream<List<Folder>> watchFolders({int? parentId}) {
    return (_db.select(_db.folders)
          ..where((f) => parentId == null
              ? f.parentId.isNull()
              : f.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> createFolder(String name, {int? parentId}) {
    return _db.into(_db.folders).insert(FoldersCompanion(
          name: Value(name),
          parentId: Value(parentId),
          // FIX: Explicitly set date in Dart so it stores as Int (timestamp)
          createdAt: Value(DateTime.now()),
          isFavorite: const Value(false),
        ));
  }

  // --- Note Operations ---
  Stream<List<Note>> watchNotes({int? folderId}) {
    return (_db.select(_db.notes)
          ..where((n) => folderId == null
              ? n.folderId.isNull()
              : n.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
                     (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> createNote(String title, String contentJson, {int? folderId}) {
    return _db.into(_db.notes).insert(NotesCompanion(
          title: Value(title),
          contentJson: Value(contentJson),
          folderId: Value(folderId),
          // FIX: Explicitly set dates in Dart so they store as Int (timestamp)
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          isPinned: const Value(false),
        ));
  }
}