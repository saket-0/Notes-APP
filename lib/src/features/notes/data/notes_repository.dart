import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

// This provider gives other files access to this Repository
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(databaseProvider));
});

// We expose the database itself via a provider for easy access
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

class NotesRepository {
  final AppDatabase _db;

  NotesRepository(this._db);

  // --- Folder Operations ---

  // Get folders inside a specific parent (or root if null)
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
        ));
  }

  // --- Note Operations ---

  // Get notes inside a specific folder (or root if null)
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
        ));
  }
}