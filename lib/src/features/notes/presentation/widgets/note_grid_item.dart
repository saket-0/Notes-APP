import 'package:flutter/material.dart';
import 'package:notes_app/src/core/database/app_database.dart';

class NoteGridItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteGridItem({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      // Fixed: Updated to Material 3 standard color
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title != null && note.title!.isNotEmpty)
                Text(
                  note.title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              if (note.title != null) const SizedBox(height: 8),
              Text(
                "Tap to view content...",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}