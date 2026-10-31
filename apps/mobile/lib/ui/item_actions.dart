import 'package:flutter/material.dart';

/// The Edit / Delete sheet shown when a saved entry is tapped. Delete asks
/// again before anything is removed.
Future<void> showItemActions(
  BuildContext context, {
  required String title,
  required VoidCallback onEdit,
  required Future<void> Function() onDelete,
  String deleteTitle = 'Delete this entry?',
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: () => Navigator.pop(sheet, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFF9B3B2A)),
            title: const Text('Delete', style: TextStyle(color: Color(0xFF9B3B2A))),
            onTap: () => Navigator.pop(sheet, 'delete'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (choice == 'edit') {
    onEdit();
  } else if (choice == 'delete') {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(deleteTitle),
        content: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await onDelete();
  }
}
