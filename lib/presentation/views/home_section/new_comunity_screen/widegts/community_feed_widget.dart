import 'package:Artleap.ai/shared/route_export.dart';

enum ItemType { post, ad }

class AdItem {
  final ItemType type;
  final int index;

  AdItem({required this.type, required this.index});
}

class CommunityFeedWidget extends ConsumerStatefulWidget {
  const CommunityFeedWidget({super.key});

  @override
  ConsumerState createState() => _CommunityFeedWidgetState();
}

class _CommunityFeedWidgetState extends ConsumerState<CommunityFeedWidget> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _shouldLoadNewAd = ValueNotifier(false);
  final _adPositions = <int>{};
  final _itemKeys = <String, GlobalKey>{};

  static const int _adFrequency = 7;
  static const double _scrollThreshold = 300.0;
  static const double _adLoadThreshold = 0.7;

  late NativeAdNotifier _nativeAdNotifier;
  late final _postsProvider = ref.read(homeScreenProvider);
  late final _userProfileNotifier = ref.read(userProfileProvider.notifier);

  @override
  void initState() {
    super.initState();

    _nativeAdNotifier = ref.read(nativeAdProvider.notifier);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_postsProvider.page == 0) {
        _postsProvider.getUserCreations();
      }

      if (RemoteConfigService.instance.showNativeAds) {
        _nativeAdNotifier.loadMultipleAds();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - _scrollThreshold &&
        !_postsProvider.isLoadingMore) {
      _postsProvider.loadMoreImages();
    }

    if (position.pixels > position.maxScrollExtent * _adLoadThreshold) {
      _shouldLoadNewAd.value = true;
    }
  }

  List<dynamic> _getItemsWithAds(List<dynamic> posts) {
    if (!RemoteConfigService.instance.showNativeAds || posts.isEmpty) {
      return posts;
    }

    final adState = ref.read(nativeAdProvider);
    if (adState.nativeAds.isEmpty) {
      return posts;
    }

    _adPositions.clear();

    final int adCount = (posts.length / _adFrequency).floor();
    for (int i = 1; i <= adCount; i++) {
      _adPositions.add(i * _adFrequency);
    }

    final List<dynamic> itemsWithAds = [];
    int adIndex = 0;

    for (int i = 0; i < posts.length; i++) {
      itemsWithAds.add(posts[i]);

      if (_adPositions.contains(i + 1) && adIndex < adState.nativeAds.length) {
        itemsWithAds.add(AdItem(type: ItemType.ad, index: adIndex++));
      }
    }

    return itemsWithAds;
  }

  void _precacheUserProfiles(List<dynamic> posts) {
    final userIds = posts
        .map((p) => p.userId)
        .whereType<String>()
        .toSet()
        .toList();

    if (userIds.isNotEmpty) {
      _userProfileNotifier.getProfilesForUserIds(userIds);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _shouldLoadNewAd.dispose();
    _nativeAdNotifier.safeDisposeAds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final homeProvider = ref.watch(homeScreenProvider);
        final displayedImages = homeProvider.getDisplayedImages();

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _precacheUserProfiles(displayedImages);
        });

        return Column(
          children: [
            CommunityHeader(
              onSearchStateChanged: (a, b) {},
              onFilterStateChanged: (x) {},
            ),
            Expanded(
              child: _buildContent(homeProvider, displayedImages, constraints),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
      HomeScreenProvider homeProvider,
      List<dynamic> displayedImages,
      BoxConstraints constraints,
      ) {
    if (homeProvider.usersData == null) {
      return _buildLoadingShimmer();
    }

    final itemsWithAds = _getItemsWithAds(displayedImages);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _shouldLoadNewAd.value = false;
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          await homeProvider.refreshUserCreations();
          if (RemoteConfigService.instance.showNativeAds) {
            _nativeAdNotifier.loadMultipleAds();
          }
        },
        child: _buildListView(itemsWithAds, homeProvider, constraints),
      ),
    );
  }

  Widget _buildListView(
      List<dynamic> itemsWithAds,
      HomeScreenProvider homeProvider,
      BoxConstraints constraints,
      ) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: constraints.maxHeight * 2,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
      semanticChildCount: itemsWithAds.length,
      itemCount: itemsWithAds.length + (homeProvider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= itemsWithAds.length) {
          return const LoadingState(
            useShimmer: true,
            shimmerItemCount: 1,
            loadingType: LoadingType.post,
          );
        }

        final item = itemsWithAds[index];

        if (item is AdItem) {
          return _buildAdItem(item, index);
        }

        return _buildPostItem(item, index, homeProvider);
      },
    );
  }

  Widget _buildAdItem(AdItem item, int listIndex) {
    final key = 'native_ad_${item.index}';
    _itemKeys.putIfAbsent(key, () => GlobalKey());

    return NativeAdPostWidget(
      key: _itemKeys[key],
      adIndex: item.index,
      onAdDisposed: () {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && RemoteConfigService.instance.showNativeAds) {
            _nativeAdNotifier.loadMultipleAds();
          }
        });
      },
    );
  }

  Widget _buildPostItem(dynamic image, int index, HomeScreenProvider homeProvider) {
    final key = 'post_${image.id}_$index';
    _itemKeys.putIfAbsent(key, () => GlobalKey());

    final profile = ref.watch(userProfileProvider.select(
          (asyncValue) {
        return asyncValue.maybeWhen(
          data: (state) => state.profilesCache[image.userId],
          orElse: () => null,
        );
      },
    ));

    return PostCard(
      key: _itemKeys[key],
      image: image,
      index: index,
      homeProvider: homeProvider,
      profileImage: profile?.user.profilePic,
    );
  }

  Widget _buildLoadingShimmer() {
    return const LoadingState(
      useShimmer: true,
      shimmerItemCount: 3,
      loadingType: LoadingType.post,
    );
  }
}