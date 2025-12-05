import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notes_app/src/features/notes/data/notes_repository.dart';
import 'package:notes_app/src/features/notes/presentation/providers/home_providers.dart';
import 'package:notes_app/src/features/notes/presentation/widgets/folder_grid_item.dart';
import 'package:notes_app/src/features/notes/presentation/widgets/note_grid_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(currentFoldersStreamProvider);
    final notesAsync = ref.watch(currentNotesStreamProvider);
    final currentFolderId = ref.watch(currentFolderIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        leading: currentFolderId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref.read(currentFolderIdProvider.notifier).state = null,
              )
            : null,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Folders Grid (Top Section)
          foldersAsync.when(
            data: (folders) => folders.isEmpty
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final folder = folders[index];
                          return FolderGridItem(
                            folder: folder,
                            onTap: () {
                              // Drill down into folder
                              ref.read(currentFolderIdProvider.notifier).state = folder.id;
                            },
                          );
                        },
                        childCount: folders.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 Folders per row
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator()),
            error: (e, st) => SliverToBoxAdapter(child: Text('Error: $e')),
          ),

          // 2. Notes Grid (Masonry / Google Keep style)
          notesAsync.when(
            data: (notes) => SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return NoteGridItem(
                    note: note,
                    onTap: () {
                      // TODO: Open Note Editor
                    },
                  );
                },
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (e, st) => SliverToBoxAdapter(child: Text('Error: $e')),
          ),
        ],
      ),
      // Temporary FAB to test adding data
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Temporary Logic: Create a dummy note to test the UI
          final repo = ref.read(notesRepositoryProvider);
          final currentId = ref.read(currentFolderIdProvider);
          repo.createNote(
            "New Note ${DateTime.now().second}",
            "Some content",
            folderId: currentId,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}