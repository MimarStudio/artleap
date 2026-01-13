import 'package:Artleap.ai/providers/help_screen_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});
  static const routeName = '/help-screen';

  final List<Map<String, dynamic>> faqItems = const [
    {
      'question': 'How do I create a new artwork?',
      'answer':
          'Tap the "+" button on the home screen to start a new creation. '
              'Select your canvas size and begin painting with our tools.',
    },
    {
      'question': 'Where are my saved artworks stored?',
      'answer': 'All your artworks are saved in the "My Profile" section. '
          'You can access them anytime from the bottom navigation.',
    },
    {
      'question': 'How do I share my artwork?',
      'answer': 'Open any artwork and tap the share icon. '
          'You can share directly to social media or save to your device.',
    },
    {
      'question': 'What subscription options are available?',
      'answer': 'We offer weekly, monthly and yearly subscriptions. '
          'Go to "Sidebar" > "Subscription plan" to view available plans.',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(helpScreenProvider);
    final notifier = ref.read(helpScreenProvider.notifier);
    AnalyticsService.instance.logButtonClick(buttonName: 'Help Screen');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help Center',
          style: AppTextstyle.interBold(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Need Help?', theme),
              const SizedBox(height: 10),
              Text(
                'We\'re here to assist you with any questions or issues you might have.',
                style: AppTextstyle.interRegular(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionHeader('Frequently Asked Questions', theme),
              const SizedBox(height: 20),
              ...faqItems.map((item) => _buildFAQItem(
                    question: item['question']!,
                    answer: item['answer']!,
                    theme: theme,
                  )),
              const SizedBox(height: 40),
              _buildSectionHeader('Still Need Help?', theme),
              const SizedBox(height: 15),
              Text(
                'Our support team is ready to help you with any questions or issues.',
                style: AppTextstyle.interRegular(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: _buildContactButton(
                  isLoading: isLoading,
                  onPressed: () => _launchEmail(notifier, context),
                  theme: theme,
                ),
              ),
              const SizedBox(height: 40),
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail(HelpScreenNotifier notifier, BuildContext context) async {
    AnalyticsService.instance.logButtonClick(buttonName: 'Contact Support');

    if (notifier.state) return;

    notifier.setLoading(true);

    try {
      const email = 'info@x-r.digital';
      const subject = 'Xr Digital App Support Request';
      const body = 'Hello Xr Digital team,\n\nI need help with...';

      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': Uri.encodeComponent(subject),
          'body': Uri.encodeComponent(body),
        },
      );

      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(
          emailLaunchUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          Uri.parse(
              'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      appSnackBar(
        'Error',
        'Failed to open email. Please ensure you have an email app installed.',
        backgroundColor: AppColors.red,
      );
    } finally {
      if (context.mounted) {
        notifier.setLoading(false);
      }
    }
  }


  Widget _buildSectionHeader(String text, ThemeData theme) {
    return Text(
      text,
      style: AppTextstyle.interBold(
        color: theme.colorScheme.onBackground,
        fontSize: 18,
      ),
    );
  }

  Widget _buildFAQItem(
      {required String question,
      required String answer,
      required ThemeData theme}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextstyle.interMedium(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTextstyle.interRegular(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ],
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: theme.colorScheme.onSurface,
        collapsedIconColor: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildContactButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : Icon(Icons.email_outlined,
              size: 20, color: theme.colorScheme.onPrimary),
      label: Text(
        isLoading ? 'Opening...' : 'Contact Support',
        style: AppTextstyle.interMedium(
          color: theme.colorScheme.onPrimary,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Text(
            'X r Digital Team',
            style: AppTextstyle.interMedium(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'We appreciate your feedback',
            style: AppTextstyle.interRegular(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
