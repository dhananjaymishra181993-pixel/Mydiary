import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/entry.dart';
import 'edit_entry_screen.dart';
import '../widgets/entry_tile.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Entry> box;
  String query = '';

  @override
  void initState() {
    super.initState();
    box = Hive.box<Entry>('entries');
  }

  List<Entry> filteredEntries() {
    final all = box.values.toList().cast<Entry>();
    if (query.isEmpty) {
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    }
    final q = query.toLowerCase();
    final filtered = all.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q) ||
          e.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> exportJson() async {
    final entries = box.values.map((e) => e.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(entries);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/diary_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to ${file.path}')),
    );
  }

  Future<void> deleteEntry(int key) async {
    // cancel any scheduled notification for this id
    await NotificationService().cancelNotification(key);
    await box.delete(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export JSON',
            onPressed: exportJson,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search title, content, tags...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Entry> b, _) {
          final list = filteredEntries();
          if (list.isEmpty) {
            return const Center(child: Text('Koi entry nahi mili.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final e = list[idx];
              return EntryTile(
                entry: e,
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditEntryScreen(entry: e)),
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete entry?'),
                      content: const Text('Are you sure you want to delete this entry?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await deleteEntry(e.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditEntryScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
