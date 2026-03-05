import 'package:flutter/material.dart';
import 'package:persona_app/core/secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'note_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final SecureStorageService _storage = SecureStorageService();
  List<Note> _notes = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final data = await _storage.readList("secure_notes");
    setState(() {
      _notes = data.map((item) => Note.fromJson(item)).toList();
    });
  }

  Future<void> _saveNotes() async {
    await _storage.write("secure_notes", _notes.map((e) => e.toJson()).toList());
  }

  void _showNoteEditor({Note? note}) {
    final titleController = TextEditingController(text: note?.title);
    final contentController = TextEditingController(text: note?.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: "Content (Markdown supported)",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    if (note == null) {
                      _notes.add(Note(
                        id: _uuid.v4(),
                        title: titleController.text,
                        content: contentController.text,
                      ));
                    } else {
                      final index = _notes.indexWhere((n) => n.id == note.id);
                      _notes[index] = Note(
                        id: note.id,
                        title: titleController.text,
                        content: contentController.text,
                      );
                    }
                  });
                  _saveNotes();
                  Navigator.pop(context);
                }
              },
              child: const Text("Save Note"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secure Notes")),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(note.title),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: MarkdownBody(data: note.content),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showNoteEditor(note: note);
                        },
                        child: const Text("Edit"),
                      ),
                    ],
                  ),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() => _notes.removeAt(index));
                  _saveNotes();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
