import 'package:Artleap.ai/domain/reels/reel_provider.dart';
import 'package:Artleap.ai/presentation/firebase_analyitcs_singleton/firebase_analtics_singleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/reel_actions_widget.dart';
import 'components/reel_video_widget.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  static const routeName = '/reels';

  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    AnalyticsService.instance.logScreenView(screenName: 'reels button event');
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(reelProvider.notifier).setCurrentReelIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reelProvider);
    final theme = Theme.of(context);

    // if (state.isLoading) {
    //   return Scaffold(
    //     backgroundColor: theme.colorScheme.surface,
    //     body: const ReelShimmerWidget(),
    //   );
    // }
    //
    // if (state.reels.isEmpty) {
    //   return Scaffold(
    //     backgroundColor: theme.colorScheme.surface,
    //     body: Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           Icon(
    //             Icons.video_library_outlined,
    //             size: 64,
    //             color: theme.colorScheme.onSurface.withOpacity(0.3),
    //           ),
    //           const SizedBox(height: 16),
    //           Text(
    //             'No reels available',
    //             style: TextStyle(
    //               color: theme.colorScheme.onSurface.withOpacity(0.5),
    //               fontSize: 16,
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    return  Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: state.reels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final reel = state.reels[index];
              final isCurrentReel = index == state.currentReelIndex;

              return Stack(
                children: [
                  ReelVideoWidget(
                    reel: reel,
                    isCurrentReel: isCurrentReel,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(

                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(reel.creatorAvatar),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  reel.creatorName,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.onSurface),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child:  Text(
                                    'Follow',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              reel.caption,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  color: theme.colorScheme.onSurface,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  reel.musicName,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ReelActionsWidget(reel: reel),
                ],
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Reels',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.blueGrey.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Text(
                            "Reels Section",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 8.0,
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16.0),
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Text(
                            "Coming Soon...",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}