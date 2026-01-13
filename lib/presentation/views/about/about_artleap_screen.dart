import 'package:Artleap.ai/presentation/firebase_analyitcs_singleton/firebase_analtics_singleton.dart';
import 'package:Artleap.ai/widgets/custom_text/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'sections/about_artleap_contact.dart';
import 'sections/about_artleap_footer.dart';
import 'sections/about_artleap_hero.dart';
import 'sections/about_artleap_mission.dart';
import 'sections/about_artleap_technology.dart';

class AboutArtleapScreen extends StatelessWidget {
  static const routeName = '/about-artleap';

  const AboutArtleapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AnalyticsService.instance.logScreenView(screenName: 'About Artleap Screen');
    return Scaffold(
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AboutArtleapHeroSection(),
              const AboutArtleapMissionSection(),
              const AboutArtleapTechnologySection(),
              const AboutArtleapContactSection(),
              const AboutArtleapFooter(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: AppText(
        'About Artleap',
          size: 20,
          color: theme.colorScheme.onPrimary,
      ),
      centerTitle: true,
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
      iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
    );
  }
}