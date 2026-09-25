import '../models/journal_entry.dart';
import '../utils/date_utils.dart';
import '../utils/validators.dart';
import 'storage_service.dart';

/// Diario personal privado. Nada sale del dispositivo.
class JournalService {
  JournalService(this._storage, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    reload();
  }

  final StorageService _storage;
  final DateTime Function() _clock;
  final List<JournalEntry> _entries = <JournalEntry>[];

  void reload() {
    _entries
      ..clear()
      ..addAll(<JournalEntry>[
        for (final item in _storage.readList(StorageKeys.journal))
          JournalEntry.fromJson(item),
      ]);
    _sort();
  }

  void _sort() {
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Entradas ordenadas de la más reciente a la más antigua.
  List<JournalEntry> get entries => List<JournalEntry>.unmodifiable(_entries);

  int get count => _entries.length;

  List<JournalEntry> byTag(String tag) =>
      _entries.where((e) => e.tags.contains(tag)).toList();

  List<JournalEntry> byDay(int day) =>
      _entries.where((e) => e.day == day).toList();

  JournalEntry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }

  /// Crea una entrada. Devuelve null si no tiene contenido.
  Future<JournalEntry?> add({
    required String text,
    String title = '',
    List<String> tags = const <String>[],
    int? day,
    JournalKind kind = JournalKind.free,
  }) async {
    final now = _clock();
    final entry = JournalEntry(
      id: LocalId.next('j'),
      createdAt: now,
      updatedAt: now,
      title: Validators.clean(title),
      text: Validators.clean(text),
      tags: _cleanTags(tags),
      day: day,
      kind: kind,
    );
    if (!entry.isValid) {
      return null;
    }
    _entries.add(entry);
    _sort();
    await _save();
    return entry;
  }

  /// Guarda o reemplaza la respuesta guiada de un día concreto.
  Future<JournalEntry?> upsertGuided({
    required int day,
    required String title,
    required String text,
    List<String> tags = const <String>[],
  }) async {
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.kind == JournalKind.guided && e.day == day) {
        final updated = e.copyWith(
          title: Validators.clean(title),
          text: Validators.clean(text),
          updatedAt: _clock(),
        );
        if (!updated.isValid) {
          return null;
        }
        _entries[i] = updated;
        await _save();
        return updated;
      }
    }
    return add(
      text: text,
      title: title,
      tags: tags,
      day: day,
      kind: JournalKind.guided,
    );
  }

  Future<bool> update(JournalEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index < 0) {
      return false;
    }
    final updated = entry.copyWith(
      title: Validators.clean(entry.title),
      text: Validators.clean(entry.text),
      tags: _cleanTags(entry.tags),
      updatedAt: _clock(),
    );
    if (!updated.isValid) {
      return false;
    }
    _entries[index] = updated;
    _sort();
    await _save();
    return true;
  }

  Future<bool> delete(String id) async {
    final before = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length == before) {
      return false;
    }
    await _save();
    return true;
  }

  Future<void> deleteAll() async {
    _entries.clear();
    await _storage.remove(StorageKeys.journal);
  }

  List<String> _cleanTags(List<String> tags) {
    final result = <String>[];
    for (final t in tags) {
      final clean = Validators.cleanTag(t);
      if (clean != null && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  Future<void> _save() async {
    await _storage.writeList(
      StorageKeys.journal,
      <Map<String, dynamic>>[for (final e in _entries) e.toJson()],
    );
  }
}
