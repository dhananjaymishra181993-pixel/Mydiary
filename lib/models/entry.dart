import 'package:hive/hive.dart';

class Entry {
  final int id;
  String title;
  String content;
  DateTime createdAt;
  List<String> tags;
  DateTime? reminder; // new: optional reminder datetime

  Entry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    List<String>? tags,
    this.reminder,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
        'reminder': reminder?.toIso8601String(),
      };

  static Entry fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as int,
        title: j['title'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        tags: List<String>.from(j['tags'] ?? []),
        reminder: j['reminder'] != null ? DateTime.parse(j['reminder'] as String) : null,
      );
}

// Manual Hive adapter (no build_runner required)
class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 0;

  @override
  Entry read(BinaryReader reader) {
    final id = reader.readInt();
    final title = reader.readString();
    final content = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final tags = reader.readList().cast<String>();
    final hasReminder = reader.readBool();
    DateTime? reminder;
    if (hasReminder) {
      reminder = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    }
    return Entry(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      tags: tags,
      reminder: reminder,
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeList(obj.tags);
    if (obj.reminder != null) {
      writer.writeBool(true);
      writer.writeInt(obj.reminder!.millisecondsSinceEpoch);
    } else {
      writer.writeBool(false);
    }
  }
}
