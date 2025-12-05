import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// 1. THIS IMPORT IS CRITICAL FOR QUILL WIDGETS
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// 2. THIS IMPORT IS CRITICAL FOR 'Value' (used in repo calls if needed)
import 'package:drift/drift.dart' hide Column; 
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:notes_app/src/core/database/app_database.dart';
import 'package:notes_app/src/features/notes/data/notes_repository.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int? noteId;
  final int? currentFolderId;

  const NoteEditorScreen({super.key, this.noteId, this.currentFolderId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final QuillController _controller = QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _titleController = TextEditingController();
  Note? _existingNote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final repo = ref.read(notesRepositoryProvider);
      _existingNote = await repo.getNote(widget.noteId!);
      
      if (_existingNote != null) {
        _titleController.text = _existingNote!.title ?? '';
        if (_existingNote!.contentJson != null && _existingNote!.contentJson!.isNotEmpty) {
           try {
             final json = jsonDecode(_existingNote!.contentJson!);
             _controller.document = Document.fromJson(json);
           } catch (e) {
             debugPrint("Error parsing JSON: $e");
           }
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    final repo = ref.read(notesRepositoryProvider);
    final title = _titleController.text.trim();
    final contentJson = jsonEncode(_controller.document.toDelta().toJson());
    if (title.isEmpty && _controller.document.isEmpty()) return;

    if (_existingNote != null) {
      final updatedNote = _existingNote!.copyWith(
        title: Value(title),
        contentJson: Value(contentJson),
        updatedAt: DateTime.now(),
      );
      await repo.updateNote(updatedNote);
    } else {
      await repo.createNote(
        title.isEmpty ? 'Untitled Note' : title,
        contentJson,
        folderId: widget.currentFolderId,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: source);

    if (photo != null) {
      // Save locally
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'note_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${const Uuid().v4()}${p.extension(photo.path)}';
      final savedImage = await File(photo.path).copy(p.join(imagesDir.path, fileName));

      // Insert into Quill
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;
      
      // Embed the file path as an image block
      _controller.replaceText(index, length, BlockEmbed.image(savedImage.path), null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          )
        ],
      ),
      body: Column(
        children: [
          // Title Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Custom Toolbar
          QuillSimpleToolbar(
            controller: _controller,
          ),
          
          const Divider(),

          // Editor Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}