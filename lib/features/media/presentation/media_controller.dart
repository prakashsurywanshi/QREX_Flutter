import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_file.dart';
import '../data/media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository();
});

class MediaState {
  final List<MediaFile> files;
  final List<String> folders;
  final String folderFilter;
  final double storageUsed;
  final int storageEntries;
  final bool loading;
  final String? error;

  const MediaState({
    this.files = const [],
    this.folders = const [],
    this.folderFilter = 'All',
    this.storageUsed = 0,
    this.storageEntries = 0,
    this.loading = false,
    this.error,
  });

  List<MediaFile> get filtered => folderFilter == 'All'
      ? files
      : files.where((f) => f.folder == folderFilter).toList();

  MediaState copyWith({
    List<MediaFile>? files,
    List<String>? folders,
    String? folderFilter,
    double? storageUsed,
    int? storageEntries,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return MediaState(
      files: files ?? this.files,
      folders: folders ?? this.folders,
      folderFilter: folderFilter ?? this.folderFilter,
      storageUsed: storageUsed ?? this.storageUsed,
      storageEntries: storageEntries ?? this.storageEntries,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MediaController extends StateNotifier<MediaState> {
  final MediaRepository _repo;

  MediaController(this._repo) : super(const MediaState());

  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final idx = await _repo.fetch();
      state = state.copyWith(
        files: idx.files,
        folders: idx.folders,
        storageUsed: idx.storageUsed,
        storageEntries: idx.storageEntries,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void filterFolder(String folder) {
    state = state.copyWith(folderFilter: folder);
  }

  Future<void> uploadFile({
    required String filePath,
    required String fileName,
    String? name,
    String folder = 'General',
    String? propertyName,
  }) async {
    await _repo.upload(
      filePath: filePath,
      fileName: fileName,
      name: name,
      folder: folder,
      propertyName: propertyName,
    );
    await load();
  }

  Future<void> deleteFile(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final mediaControllerProvider =
    StateNotifierProvider<MediaController, MediaState>((ref) {
  return MediaController(ref.watch(mediaRepositoryProvider));
});