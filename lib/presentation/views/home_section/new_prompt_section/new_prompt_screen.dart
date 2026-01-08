import 'package:Artleap.ai/providers/keyboard_provider.dart';
import 'package:Artleap.ai/providers/prompt_nav_provider.dart';
import 'prompt_screen_widgets/prompt_top_bar.dart';
import 'sections/edit_section/prompt_edit_screen.dart';
import 'sections/new_create_section/prompt_create_screen.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class PromptScreen extends ConsumerStatefulWidget {
  const PromptScreen({super.key});

  @override
  ConsumerState<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends ConsumerState<PromptScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        if (mounted) {
          ref.read(userProfileProvider.notifier).updateUserCredits();
          AnalyticsService.instance.logScreenView(screenName: 'Prompt Screen');
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentNav = ref.watch(promptNavProvider);
    final isExpanded = ref.watch(isDropdownExpandedProvider);
    final userProfile = ref.watch(userProfileProvider).value!.userProfile!.user;
    ref.watch(keyboardVisibleProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        key: _scaffoldKey,
        drawer: ProfileDrawer(
          profileImage: userProfile.profilePic ?? '',
          userName: userProfile.username ?? 'User',
          userEmail: userProfile.email ?? 'guest@example.com',
        ),
        body: GestureDetector(
          onTap: () {
            if (isExpanded) {
              ref.read(isDropdownExpandedProvider.notifier).state = false;

            }
          },
          child: Column(
            children: [
              HomeScreenTopBar(
                onMenuTap: (){
                  AnalyticsService.instance.logButtonClick(buttonName: 'Hamburger Icon Click');
                  final analyticsService = ref.read(analyticsServiceProvider);
                  analyticsService.logCustomEvent(
                      eventName: 'Hamburger_Icon_clicked',
                      parameters: {
                        'screen': 'Prompt_screen',
                      });
                  _scaffoldKey.currentState?.openDrawer();
                  ref.read(keyboardControllerProvider).hideKeyboard(context);
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    _buildCurrentScreen(currentNav),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(PromptNavItem navItem) {
    switch (navItem) {
      case PromptNavItem.create:
        return const PromptCreateScreenRedesign();
      case PromptNavItem.edit:
        return const PromptEditScreen();
      case PromptNavItem.animate:
        return Center(
          child: Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        );
      case PromptNavItem.enhance:
        return Center(
          child: Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        );
    }
  }
}