import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repo/save_repository.dart';
import 'providers_setup.dart';

class SaveNotifier extends StateNotifier<AsyncValue<Map<String, bool>>> {
  final SaveRepository _saveRepository;

  SaveNotifier(this._saveRepository)
      : super(const AsyncValue.loading()) {
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    try {
      final savedPosts = await _saveRepository.getSavedPosts();
      final savedStatus = <String, bool>{};

      for (final savedPost in savedPosts) {
        savedStatus[savedPost.image] = true;
      }

      state = AsyncValue.data(savedStatus);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleSave(String imageId) async {
    final currentState = state;

    try {
      if (currentState.hasValue) {
        final currentSaveStatus = currentState.value ?? {};
        final currentlySaved = currentSaveStatus[imageId] ?? false;
        final newStatus = Map<String, bool>.from(currentSaveStatus);
        newStatus[imageId] = !currentlySaved;
        state = AsyncValue.data(newStatus);

        if (currentlySaved) {
          await _saveRepository.unsavePost(imageId);
        } else {
          await _saveRepository.savePost(imageId);
        }
        state = AsyncValue.data(newStatus);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      await _loadSavedStatus();
    }
  }

  Future<bool> isSaved(String imageId) async {
    try {
      return await _saveRepository.isSaved(imageId);
    } catch (error) {
      return false;
    }
  }

  Future<List<String>> getSavedImageIds() async {
    try {
      final savedPosts = await _saveRepository.getSavedPosts();
      return savedPosts.map((post) => post.image).toList();
    } catch (error) {
      return [];
    }
  }

  Future<void> refreshSavedStatus() async {
    await _loadSavedStatus();
  }

  Future<int> getSavedCount() async {
    try {
      return await _saveRepository.getSavedCount();
    } catch (error) {
      return 0;
    }
  }
}

final saveProvider = StateNotifierProvider.autoDispose<SaveNotifier, AsyncValue<Map<String, bool>>>(
      (ref) {
    final saveRepository = ref.watch(saveRepositoryProvider);
    return SaveNotifier(saveRepository);
  },
);