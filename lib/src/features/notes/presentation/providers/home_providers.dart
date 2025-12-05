import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/src/core/database/app_database.dart';
import 'package:notes_app/src/features/notes/data/notes_repository.dart';

// 1. Holds the ID of the folder we are currently viewing (null = Root)
final currentFolderIdProvider = StateProvider<int?>((ref) => null);

// 2. Fetches the SUB-FOLDERS for the current view
final currentFoldersStreamProvider = StreamProvider.autoDispose<List<Folder>>((ref) {
  final currentId = ref.watch(currentFolderIdProvider);
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchFolders(parentId: currentId);
});

// 3. Fetches the NOTES for the current view
final currentNotesStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final currentId = ref.watch(currentFolderIdProvider);
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchNotes(folderId: currentId);
});