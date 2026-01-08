import 'package:Artleap.ai/shared/route_export.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const routeName = '/privacy-policy';

  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AnalyticsService.instance.logButtonClick(buttonName: 'Privacy Policy');

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(theme),
                const SizedBox(height: 32),
                _buildPolicyContent(theme),
                const SizedBox(height: 24),
                _buildFooterSection(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'Privacy Policy',
        style: AppTextstyle.interBold(
          fontSize: 20,
          color: theme.colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      backgroundColor: theme.colorScheme.surface,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Privacy Policy',
          style: AppTextstyle.interBold(
            fontSize: 32,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Effective Date: January 1, 2025',
          style: AppTextstyle.interRegular(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'At ArtLeap.AI, we value your privacy. This Privacy Policy explains how we collect, use, and protect your information when you use our photo generator AI application ("App"). By using the App, you agree to the practices outlined in this policy.',
            style: AppTextstyle.interRegular(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyContent(ThemeData theme) {
    return Column(
      children: [
        _buildPolicySection(
          icon: Icons.collections_bookmark,
          title: "1. Information We Collect",
          content: """
1.1 Personal Information

Account Details: If you register an account, we may collect your name, email address, and other optional profile information.

Payment Information: If you make in-app purchases, your payment is securely processed by a third-party billing platform. We do not store or access your payment details.

1.2 Uploaded Content

User Content: Any images or photos you upload for AI processing are temporarily processed and not stored longer than necessary to deliver the service.

1.3 Device and Usage Data

Device Details: We may collect data such as device model, operating system version, app version, and device identifiers to ensure optimal performance.

Usage Logs: We collect information about your interactions with the App, such as features used and error reports, to improve functionality.

1.4 Analytics and Tracking

We may use anonymous cookies or similar technologies to analyze user behavior and enhance your experience with the App. These tools help us understand usage trends and optimize features.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.analytics,
          title: "2. How We Use Your Information",
          content: """
We use collected information to:

• Operate and enhance the App's performance and features.
• Process your content and deliver AI-generated results.
• Provide user support and respond to inquiries.
• Customize user experience and show relevant features.
• Comply with legal and policy requirements.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.share,
          title: "3. Sharing of Information",
          content: """
We do not sell or rent your personal information. We may share limited data with:

• Trusted service providers who help us operate, maintain, and improve the App.
• Legal authorities, only when required to comply with applicable laws or to protect rights and safety.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.security,
          title: "4. Data Security",
          content: """
We implement industry-standard security practices to protect your information, including encryption, secure data storage, and access controls. While we strive to protect all user data, no digital system is completely immune to risks.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.security,
          title: "5. Children’s Privacy",
          content: """
The App
is not intended for children under 13. We do not knowingly collect personal
information from anyone under this age. If such data is identified, it will be
promptly deleted.

Published Standards — Child Safety
Last updated: October 2025
At ArtLeap, we are committed to maintaining a safe and respectful environment for all users, especially minors.
We strictly prohibit:

Any content, activity, or behaviour that involves or promotes Child Sexual Abuse and Exploitation (CSAE).
The sharing, creation, or distribution of any sexualized or harmful content involving minors.
Grooming, harassment, or solicitation of minors in any form.
We actively moderate and report any violations of these standards to the appropriate legal authorities in accordance with applicable laws.
If you encounter content or behaviour that violates these standards, please report it immediately through our in-app reporting tools or by contacting us at:

info@x-r.digital
These standards apply to all users and content within XR Digital""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.person_outline,
          title: "6. Your Rights",
          content: """
Depending on your location, you may have the right to:

• Access your personal data.
• Update or correct inaccurate information.
• Request deletion of your account or data.
• Disable analytics or tracking features in your device or app settings.

To exercise your rights, please contact us at info@x-r.digital.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.storage,
          title: "7. Data Retention",
          content: """
• Uploaded images are stored temporarily and deleted after processing.
• Other data is retained only as long as needed for operational, legal, or business purposes.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.child_care,
          title: "8. Children's Privacy",
          content: """
The App is not intended for children under 13. We do not knowingly collect personal information from anyone under this age. If such data is identified, it will be promptly deleted.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.update,
          title: "9. Policy Updates",
          content: """
We may update this Privacy Policy to reflect changes to our features or legal requirements. Any updates will be posted within the App. Your continued use of the App indicates acceptance of the updated policy.
""",
          theme: theme,
        ),
        _buildPolicySection(
          icon: Icons.contact_support,
          title: "10. Contact Us",
          content: """
For any privacy-related inquiries or concerns, please reach out to us:

📧 Email: info@x-r.digital
""",
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildPolicySection({
    required IconData icon,
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextstyle.interBold(
                      fontSize: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                content,
                style: AppTextstyle.interRegular(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Divider(
          color: theme.colorScheme.outline.withOpacity(0.3),
          thickness: 0.5,
          height: 1,
        ),
        const SizedBox(height: 24),
        Text(
          'By using ArtLeap.AI, you acknowledge that you have read and understood this Privacy Policy.',
          style: AppTextstyle.interRegular(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          '© ${DateTime.now().year} ArtLeap.AI\nAll rights reserved.',
          style: AppTextstyle.interRegular(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
