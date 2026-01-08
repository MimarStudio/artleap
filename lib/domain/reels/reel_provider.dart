import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reel_model.dart';

final mockReels = [
  ReelModel(
    id: '1',
    videoUrl: 'https://youtube.com/shorts/nqS6yQRHGD8?si=JZSZuOijONopOMct',
    thumbnailUrl: 'https://www.techsmith.com/wp-content/uploads/2021/02/video-thumbnails-hero-1.png',
    creatorName: 'Creative Artist',
    creatorAvatar: 'https://static.vecteezy.com/system/resources/thumbnails/021/185/682/small/man-in-motocross-helmet-racer-rider-cyclist-concept-suitable-for-avatar-profiles-t-shirt-design-print-sticker-poster-vector.jpg',
    caption: 'Amazing AI generated art process! 🎨✨',
    likes: 2543,
    comments: 142,
    shares: 89,
    musicName: 'Original Sound - Creative Artist',
    duration: const Duration(seconds: 30),
  ),
  ReelModel(
    id: '2',
    videoUrl: 'https://youtube.com/shorts/nqS6yQRHGD8?si=JZSZuOijONopOMct',
    thumbnailUrl: 'https://www.techsmith.com/wp-content/uploads/2021/02/video-thumbnails-hero-1.png',
    creatorName: 'Digital Designer',
    creatorAvatar: 'https://static.vecteezy.com/system/resources/thumbnails/021/185/682/small/man-in-motocross-helmet-racer-rider-cyclist-concept-suitable-for-avatar-profiles-t-shirt-design-print-sticker-poster-vector.jpg',
    caption: 'Transforming ideas into digital masterpieces 🖌️',
    likes: 1876,
    comments: 93,
    shares: 45,
    musicName: 'Trending Sound - Design Vibes',
    duration: const Duration(seconds: 25),
  ),
];

class ReelState {
  final List<ReelModel> reels;
  final int currentReelIndex;
  final bool isLoading;
  final bool isMuted;
  final Map<String, bool> likes;

  const ReelState({
    required this.reels,
    required this.currentReelIndex,
    required this.isLoading,
    required this.isMuted,
    required this.likes,
  });

  ReelState copyWith({
    List<ReelModel>? reels,
    int? currentReelIndex,
    bool? isLoading,
    bool? isMuted,
    Map<String, bool>? likes,
  }) {
    return ReelState(
      reels: reels ?? this.reels,
      currentReelIndex: currentReelIndex ?? this.currentReelIndex,
      isLoading: isLoading ?? this.isLoading,
      isMuted: isMuted ?? this.isMuted,
      likes: likes ?? this.likes,
    );
  }
}

class ReelNotifier extends StateNotifier<ReelState> {
  ReelNotifier() : super(const ReelState(
    reels: [],
    currentReelIndex: 0,
    isLoading: true,
    isMuted: false,
    likes: {},
  )) {
    _loadReels();
  }

  Future<void> _loadReels() async {
    await Future.delayed(const Duration(seconds: 2));

    final likesMap = {for (var reel in mockReels) reel.id: reel.isLiked};

    state = state.copyWith(
      reels: mockReels,
      isLoading: false,
      likes: likesMap,
    );
  }

  void setCurrentReelIndex(int index) {
    if (index >= 0 && index < state.reels.length) {
      state = state.copyWith(currentReelIndex: index);
    }
  }

  void toggleLike(String reelId) {
    final currentLikes = Map<String, bool>.from(state.likes);
    currentLikes[reelId] = !(currentLikes[reelId] ?? false);

    state = state.copyWith(likes: currentLikes);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void incrementComment(String reelId) {
    // Will be implemented when backend is integrated
  }

  void incrementShare(String reelId) {
    // Will be implemented when backend is integrated
  }

  void addReel(ReelModel reel) {
    final newReels = List<ReelModel>.from(state.reels)..add(reel);
    state = state.copyWith(reels: newReels);
  }

  void refreshReels() {
    state = state.copyWith(isLoading: true);
    _loadReels();
  }
}

final reelProvider = StateNotifierProvider<ReelNotifier, ReelState>((ref) {
  return ReelNotifier();
});