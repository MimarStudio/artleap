// import 'package:Artleap.ai/shared/route_export.dart';
//
// class SmartNativeAd extends ConsumerStatefulWidget {
//   final EdgeInsetsGeometry margin;
//   final EdgeInsetsGeometry padding;
//   final double? height;
//   final bool showAdLabel;
//   final String adLabelText;
//   final bool showLoadingState;
//   final bool showErrorState;
//
//   const SmartNativeAd({
//     super.key,
//     this.margin = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//     this.padding = const EdgeInsets.all(10),
//     this.height,
//     this.showAdLabel = true,
//     this.adLabelText = 'Advertisement',
//     this.showLoadingState = true,
//     this.showErrorState = true,
//   });
//
//   @override
//   ConsumerState<SmartNativeAd> createState() => _SmartNativeAdState();
// }
//
// class _SmartNativeAdState extends ConsumerState<SmartNativeAd> {
//   bool _adLoaded = false;
//   bool _shouldLoadAd = true;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     if (_shouldLoadAd) {
//       _shouldLoadAd = false;
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _loadAd();
//       });
//     }
//   }
//
//   Future<void> _loadAd() async {
//     final adState = ref.read(nativeAdProvider);
//     final adsList = adState.smallNativeAds;
//
//     if (adsList.isNotEmpty) {
//       if (mounted) {
//         setState(() {
//           _adLoaded = true;
//         });
//       }
//       return;
//     }
//
//     // Load small native ads
//     await ref.read(nativeAdProvider.notifier).loadSmallNativeAds();
//
//     if (mounted) {
//       setState(() {
//         _adLoaded = true;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final adState = ref.watch(nativeAdProvider);
//     final centralAdState = ref.watch(centralAdManagementProvider);
//
//     final adsList = adState.smallNativeAds;
//     final isLoading = adState.isLoadingSmall;
//     final isLoaded = adState.isSmallLoaded;
//     final isAdTypeLoaded = centralAdState.adLoadStatus['smallNative'] ?? false;
//
//     if (isLoading && widget.showLoadingState && !_adLoaded) {
//       return _buildLoadingPlaceholder(context);
//     }
//
//     if (adState.errorMessage != null && !isLoaded && adsList.isEmpty && widget.showErrorState) {
//       return _buildErrorPlaceholder(context, adState.errorMessage!);
//     }
//
//     // Just get the first ad from the list
//     final ad = adsList.isNotEmpty ? adsList.first : null;
//
//     if (!adState.showAds || !isAdTypeLoaded || !isLoaded || adsList.isEmpty || ad == null) {
//       return const SizedBox.shrink();
//     }
//
//     return Container(
//       margin: widget.margin,
//       padding: widget.padding,
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
//           if (widget.showAdLabel)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Icon(
//                   Icons.ads_click,
//                   size: 12,
//                   color: theme.colorScheme.onSurface.withOpacity(0.5),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   widget.adLabelText,
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: theme.colorScheme.onSurface.withOpacity(0.5),
//                   ),
//                 ),
//               ],
//             ),
//           if (widget.showAdLabel) const SizedBox(height: 8),
//           SizedBox(
//             height: widget.height ?? 90,
//             width: double.infinity,
//             child: AdWidget(ad: ad),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLoadingPlaceholder(BuildContext context) {
//     final theme = Theme.of(context);
//     final placeholderHeight = widget.height ?? 90;
//
//     return Container(
//       margin: widget.margin,
//       padding: widget.padding,
//       height: placeholderHeight,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainer,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.outline.withOpacity(0.1),
//           width: 1,
//         ),
//       ),
//       child: Center(
//         child: CircularProgressIndicator(
//           strokeWidth: 2,
//           color: theme.colorScheme.primary,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildErrorPlaceholder(BuildContext context, String error) {
//     final theme = Theme.of(context);
//     final placeholderHeight = widget.height ?? 90;
//
//     return Container(
//       margin: widget.margin,
//       padding: widget.padding,
//       height: placeholderHeight,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainer,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.error.withOpacity(0.1),
//           width: 1,
//         ),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline,
//               color: theme.colorScheme.error,
//               size: 24,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Ad failed to load',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: theme.colorScheme.error,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }