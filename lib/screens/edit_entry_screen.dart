import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/entry.dart';
import '../services/notification_service.dart';

class EditEntryScreen extends StatefulWidget {
  final Entry? entry;
  const EditEntryScreen({super.key, this.entry});

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  final _titleCtl = TextEditingController();
  final _contentCtl = TextEditingController();
  final _tagsCtl = TextEditingController();
  DateTime? _reminder;
  late Box<Entry> box;

  @override
  void initState() {
    super.initState();
    box = Hive.box<Entry>('entries');
    if (widget.entry != null) {
      _titleCtl.text = widget.entry!.title;
      _contentCtl.text = widget.entry!.content;
      _tagsCtl.text = widget.entry!.tags.join(', ');
      _reminder = widget.entry!.reminder;
    }
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminder ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _reminder != null ? TimeOfDay.fromDateTime(_reminder!) : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> save() async {
    final title = _titleCtl.text.trim();
    final content = _contentCtl.text.trim();
    final tags = _tagsCtl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter title or content')));
      return;
    }

    if (widget.entry != null) {
      final e = widget.entry!;
      final oldReminder = e.reminder;
      e.title = title;
      e.content = content;
      e.tags = tags;
      e.reminder = _reminder;
      await box.put(e.id, e);

      // update notifications
      if (oldReminder != null && _reminder == null) {
        await NotificationService().cancelNotification(e.id);
      } else if (_reminder != null) {
        await NotificationService().cancelNotification(e.id);
        await NotificationService().scheduleNotification(
          id: e.id,
          title: 'Diary: ${e.title.isEmpty ? '(No title)' : e.title}',
          body: e.content.isEmpty ? 'You set a reminder for this entry.' : (e.content.length > 100 ? '${e.content.substring(0, 100)}...' : e.content),
          scheduledDate: _reminder!,
        );
      }
    } else {
      final id = DateTime.now().millisecondsSinceEpoch;
      final e = Entry(id: id, title: title, content: content, createdAt: DateTime.now(), tags: tags, reminder: _reminder);
      await box.put(e.id, e);
      if (_reminder != null) {
        await NotificationService().scheduleNotification(
          id: e.id,
          title: 'Diary: ${e.title.isEmpty ? '(No title)' : e.title}',
          body: e.content.isEmpty ? 'You set a reminder for this entry.' : (e.content.length > 100 ? '${e.content.substring(0, 100)}...' : e.content),
          scheduledDate: _reminder!,
        );
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _contentCtl.dispose();
    _tagsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Entry' : 'New Entry')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentCtl,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsCtl,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.alarm),
                  label: Text(_reminder == null ? 'Set reminder' : 'Change reminder'),
                ),
                const SizedBox(width: 8),
                if (_reminder != null)
                  Text('${_reminder!.toLocal()}'.split('.').first),
                const Spacer(),
                if (_reminder != null)
                  TextButton(
                    onPressed: () => setState(() => _reminder = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
