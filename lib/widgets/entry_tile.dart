import 'package:flutter/material.dart';
import '../models/entry.dart';
import 'package:intl/intl.dart';

class EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EntryTile({super.key, required this.entry, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_jm();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        title: Text(entry.title.isEmpty ? '(No title)' : entry.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.content.length > 100 ? '${entry.content.substring(0, 100)}...' : entry.content),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(fmt.format(entry.createdAt), style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                if (entry.reminder != null)
                  Row(
                    children: [
                      const Icon(Icons.alarm, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(fmt.format(entry.reminder!), style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ],
                  ),
                const SizedBox(width: 8),
                if (entry.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: entry.tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') {
              onEdit?.call();
            } else if (v == 'delete') {
              onDelete?.call();
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
