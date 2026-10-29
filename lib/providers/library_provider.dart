import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_model.dart';
import '../repositories/library_repository.dart';

final libraryRepositoryProvider = Provider((ref) => LibraryRepository());

final libraryListProvider = StateNotifierProvider<LibraryNotifier, List<LibraryRecord>>((ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return LibraryNotifier(repository);
});

class LibraryNotifier extends StateNotifier<List<LibraryRecord>> {
  final LibraryRepository _repository;

  LibraryNotifier(this._repository) : super([]) {
    loadLibraryRecords();
  }

  Future<void> loadLibraryRecords() async {
    try {
      state = await _repository.getLibraryRecords();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addLibraryRecord(LibraryRecord record) async {
    await _repository.addLibraryRecord(record);
    await loadLibraryRecords();
  }

  Future<void> updateLibraryRecord(LibraryRecord record) async {
    await _repository.updateLibraryRecord(record);
    await loadLibraryRecords();
  }
}
