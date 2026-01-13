import 'package:Artleap.ai/presentation/views/home_section/new_prompt_section/prompt_screen_widgets/prompt_enhancer_button.dart';
import 'package:Artleap.ai/providers/keyboard_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'package:Artleap.ai/providers/prompt_enhancer_provider.dart';

class PromptInputRedesign extends ConsumerWidget {
  const PromptInputRedesign({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final enhancer = ref.watch(promptEnhancerProvider);

    final maxHeight = screenSize.height * 0.4;
    final minHeight = 140.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Enter Prompt",
              style: AppTextstyle.interMedium(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            _buildCharacterCounter(ref, theme, enhancer),
          ],
        ),
        12.spaceY,
        Container(
          constraints: BoxConstraints(
            minHeight: minHeight,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                TextField(
                  controller: ref.watch(generateImageProvider).promptTextController,
                  maxLines: null,
                  onChanged: (value) {
                    ref.watch(generateImageProvider).checkSexualWords(value);
                    if (!enhancer.isEnhancedMode) {
                      enhancer.setOriginalPrompt(value);
                    }
                  },
                  onTap: () {
                    ref.read(keyboardControllerProvider).setVisible(true);
                  },
                  style: AppTextstyle.interMedium(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: "Describe the image you want to generate..'",
                    hintStyle: AppTextstyle.interMedium(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    hintMaxLines: 5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PromptEnhancerButton(
                        promptController: ref.watch(generateImageProvider).promptTextController,
                        onEnhanced: () {
                          AnalyticsService.instance.logButtonClick(buttonName: 'prompt enhancer button');
                          final analyticsService = ref.read(analyticsServiceProvider);
                          analyticsService.logCustomEvent(
                              eventName: 'Prompt_enhancer_button_clicked',
                              parameters: {
                                'screen': 'Prompt_screen',
                              });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCounter(WidgetRef ref, ThemeData theme, PromptEnhancerProvider enhancer) {
    final currentPrompt = enhancer.currentPrompt;
    final characterCount = currentPrompt.length;

    return Row(
      children: [
        if (enhancer.isEnhancedMode)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Enhanced',
              style: AppTextstyle.interMedium(
                color: theme.colorScheme.primary,
                fontSize: 10,
              ),
            ),
          ),
        Text(
          "$characterCount/1000",
          style: AppTextstyle.interMedium(
            color: characterCount > 800
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}