import 'package:Artleap.ai/presentation/views/feedback/feedback_dialog.dart';

import 'components/action_buttons_row.dart';
import 'components/image_results_grid.dart';
import 'components/result_header.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class ResultScreenRedesign extends ConsumerStatefulWidget {
  const ResultScreenRedesign({super.key});
  static const String routeName = "result_screen";

  @override
  ConsumerState<ResultScreenRedesign> createState() =>
      _ResultScreenRedesignState();
}

class _ResultScreenRedesignState extends ConsumerState<ResultScreenRedesign> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = UserData.ins.userId;
      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      centralAdNotifier.setWidgetRef(ref);
      centralAdNotifier.loadSmallNativeAds();
      if (userId != null && userId.isNotEmpty) {
        ref.read(userProfileProvider.notifier).getUserProfileData(userId);
      } else {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FeedbackNavigationDialogHelper.resetDialogShownState();
      _showFeedbackDialogAfterDelay();
    });
  }



  void _showFeedbackDialogAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      await FeedbackNavigationDialogHelper.checkAndShowFeedbackDialog(
        context: context,
        ref: ref,
        pageUrl: '/result_screen',
        featurePath: 'result_screen',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(generateImageProvider).isGenerateImageLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            color: theme.colorScheme.surface,
            height: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: HomeScreenTopBar(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const ResultHeader(),
            const SizedBox(height: 24),
            ImageResultsGrid(ref: ref),
            const SizedBox(height: 24),
            if (!isLoading) ActionButtonsRow(ref: ref),
            const SizedBox(height: 40),
            // if (!isLoading)
            //   const FeatureButton(
            //     icon: Icons.auto_awesome,
            //     label: "Re Generate",
            //     isPrimary: true,
            //   ),
            // const SizedBox(height: 24),
            // PromptSection(ref: ref),
            // const SizedBox(height: 20),
            // if (!isLoading) ...[
            //   const FeatureButton(
            //     icon: Icons.open_in_full,
            //     label: "Upscale",
            //     isPrimary: true,
            //   ),
            //   const SizedBox(height: 12),
            //   const FeatureButton(
            //     icon: Icons.brush_outlined,
            //     label: "Add/Remove Object",
            //     isPrimary: true,
            //   ),
            // ],
            // _ResultNativeAd(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
//
// class _ResultNativeAd extends ConsumerWidget {
//   const _ResultNativeAd();
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     final centralAdState = ref.watch(centralAdManagementProvider);
//     final nativeAdState = ref.watch(nativeAdProvider);
//
//     final adsList = nativeAdState.smallNativeAds;
//     final isLoading = nativeAdState.isLoadingSmall;
//     final isAdTypeLoaded = centralAdState.adLoadStatus['smallNative'] ?? false;
//
//     if (isLoading) {
//       return Container(
//         margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         padding: const EdgeInsets.all(10),
//         height: 90,
//         decoration: BoxDecoration(
//           color: theme.colorScheme.surfaceContainer,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: theme.colorScheme.outline.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//         child: Center(
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             color: theme.colorScheme.primary,
//           ),
//         ),
//       );
//     }
//
//     if (nativeAdState.errorMessage != null && adsList.isEmpty && isAdTypeLoaded) {
//       return Container(
//         margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         padding: const EdgeInsets.all(10),
//         height: 90,
//         decoration: BoxDecoration(
//           color: theme.colorScheme.surfaceContainer,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: theme.colorScheme.error.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.error_outline,
//                 color: theme.colorScheme.error,
//                 size: 24,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Ad failed to load',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: theme.colorScheme.error,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     final ad = adsList.isNotEmpty ? adsList.first : null;
//
//     if (!nativeAdState.showAds || !isAdTypeLoaded || adsList.isEmpty || ad == null) {
//       return const SizedBox.shrink();
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainer,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.outline.withOpacity(0.1),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: theme.colorScheme.shadow.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Icon(
//                 Icons.ads_click,
//                 size: 12,
//                 color: theme.colorScheme.onSurface.withOpacity(0.5),
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 'Advertisement',
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: theme.colorScheme.onSurface.withOpacity(0.5),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             height: 90,
//             width: double.infinity,
//             child: AdWidget(ad: ad),
//           ),
//         ],
//       ),
//     );
//   }
// }