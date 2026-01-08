import 'package:Artleap.ai/shared/route_export.dart';
import 'package:Artleap.ai/domain/api_services/api_response.dart';
import '../../../domain/payment/apple_payment_service.dart';
import 'payment_components/cancel_purchase_button.dart';
import 'payment_components/payment_method_card.dart';
import 'payment_components/subscribe_button.dart';
import 'payment_components/subscription_plan_card.dart';
import 'payment_components/terms_condition_text.dart';

class ApplePaymentScreen extends ConsumerStatefulWidget {
  static const String routeName = "apple_payment_screen";
  final SubscriptionPlanModel plan;

  const ApplePaymentScreen({super.key, required this.plan});

  @override
  ConsumerState<ApplePaymentScreen> createState() => _ApplePaymentScreenState();
}

class _ApplePaymentScreenState extends ConsumerState<ApplePaymentScreen> {
  bool _isMounted = false;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeApplePayment();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _isMounted = false;
    _cleanupApplePayment();
    super.dispose();
  }

  void _safeStateUpdate(VoidCallback callback) {
    if (_isMounted && !_isDisposing) {
      if (mounted) {
        callback();
      }
    }
  }

  // Safe navigation method
  void _safeNavigate(String routeName) {
    if (_isMounted && !_isDisposing && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposing) {
          Navigator.pushReplacementNamed(context, routeName);
        }
      });
    }
  }

  void _safeSnackBar(String title, String message, {Color backgroundColor = AppColors.red}) {
    if (_isMounted && !_isDisposing && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposing) {
          appSnackBar(title, message, backgroundColor: backgroundColor);
        }
      });
    }
  }

  Future<void> _initializeApplePayment() async {
    try {
      final userId = UserData.ins.userId;
      if (userId == null) return;

      final applePaymentService = ref.read(applePaymentServiceProvider(userId));
      final initialized = await applePaymentService.initialize();

      if (initialized && _isMounted && !_isDisposing) {
        _safeStateUpdate(() {
          ref.read(inAppPurchaseInitializedProvider.notifier).state = true;
        });
      }
    } catch (e) {
      // Silent fail - initialization errors are handled in purchase flow
    }
  }

  void _cleanupApplePayment() {
    final userId = UserData.ins.userId;
    if (userId != null) {
      try {
        final applePaymentService = ref.read(applePaymentServiceProvider(userId));
        applePaymentService.dispose();
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  }

  Future<void> _handleSubscription() async {
    if (ref.read(paymentLoadingProvider)) return;
    AnalyticsService.instance.logButtonClick(buttonName: 'Subscription Button Click(Apple)');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'subscription_button_clicked(Apple Payment Page)',
        parameters: {
          'screen': 'Payment_page',
        });
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final userId = UserData.ins.userId;

    if (userId == null) {
      _safeSnackBar('Error', 'User not found');
      return;
    }

    if (paymentMethod == 'apple' && !ref.read(inAppPurchaseInitializedProvider)) {
      _safeSnackBar('Error', 'App Store payment service not initialized');
      return;
    }

    if (!ref.read(termsAcceptedProvider)) {
      _safeSnackBar('Error', 'Please accept the terms and conditions');
      return;
    }

    _safeStateUpdate(() {
      ref.read(paymentLoadingProvider.notifier).state = true;
    });

    try {
      if (paymentMethod == 'apple') {
        await _handleApplePayment(userId);
      } else if (paymentMethod == 'stripe') {
        await _handleStripePayment(userId);
      } else {
        _safeStateUpdate(() {
          ref.read(paymentLoadingProvider.notifier).state = false;
        });
        _safeSnackBar('Error', 'Select Payment Method First');
      }
    } catch (e) {
      _safeStateUpdate(() {
        ref.read(paymentLoadingProvider.notifier).state = false;
      });
      _safeSnackBar('Error', 'An unexpected error occurred');
    }
  }

  Future<void> _handleApplePayment(String userId) async {
    final applePaymentService = ref.read(applePaymentServiceProvider(userId));
    final success = await applePaymentService.purchaseSubscription(widget.plan, context);

    if (!success && _isMounted && !_isDisposing) {
      _safeStateUpdate(() {
        ref.read(paymentLoadingProvider.notifier).state = false;
      });
    }
  }

  Future<void> _handleStripePayment(String userId) async {
    final paymentService = ref.read(paymentServiceProvider(userId));
    final amount = (widget.plan.price * 100).toInt();

    final response = await paymentService.purchaseStripeSubscription(
      planId: widget.plan.id,
      amount: amount,
      currency: 'usd',
      context: context,
      ref: ref,
    );

    if (response.status == Status.completed) {
      _safeSnackBar('Success', 'Subscription created successfully', backgroundColor: AppColors.green);

      _safeStateUpdate(() {
        ref.read(paymentLoadingProvider.notifier).state = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        _safeNavigate(BottomNavBar.routeName);
      });
    } else {
      _safeStateUpdate(() {
        ref.read(paymentLoadingProvider.notifier).state = false;
      });
      _safeSnackBar('Error', response.message ?? 'Stripe purchase failed');
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDisposing) {
      final userId = UserData.ins.userId;
      if (userId != null) {
        try {
          final applePaymentService = ref.read(applePaymentServiceProvider(userId));
          applePaymentService.cancelPurchase();
        } catch (e) {

        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(paymentLoadingProvider);
    final selectedPaymentMethod = ref.watch(selectedPaymentMethodProvider);
    final isInitialized = ref.watch(inAppPurchaseInitializedProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubscriptionPlanCard(plan: widget.plan),
                const SizedBox(height: 30),
                _buildPaymentMethodSection(theme, isInitialized, selectedPaymentMethod),
                const SizedBox(height: 24),
                TermsAndConditions(
                  onTermsChanged: (value) {
                    if (value != null && _isMounted && !_isDisposing) {
                      _safeStateUpdate(() {
                        ref.read(termsAcceptedProvider.notifier).state = value;
                      });
                    }
                  },
                  isAccepted: ref.watch(termsAcceptedProvider),
                ),
                const SizedBox(height: 32),
                SubscribeButton(
                  isLoading: isLoading,
                  isEnabled: ref.watch(termsAcceptedProvider),
                  onPressed: _handleSubscription,
                ),
                const SizedBox(height: 16),
                if (isLoading && selectedPaymentMethod == 'apple')
                  CancelPurchaseButton(
                    onCancel: () {
                      final userId = UserData.ins.userId;
                      if (userId != null && _isMounted && !_isDisposing) {
                        final applePaymentService = ref.read(applePaymentServiceProvider(userId));
                        applePaymentService.cancelPurchase();
                        _safeStateUpdate(() {
                          ref.read(paymentLoadingProvider.notifier).state = false;
                        });
                      }
                    },
                  ),
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
        'Confirm Your Subscription',
        style: AppTextstyle.interBold(fontSize: 16, color: theme.colorScheme.onSurface),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () {
          if (_isMounted && !_isDisposing) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildPaymentMethodSection(ThemeData theme, bool isInitialized, String selectedPaymentMethod) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: AppTextstyle.interBold(
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            if (isInitialized)
              PaymentMethodCard(
                icon: Icons.apple_rounded,
                title: 'App Store',
                isSelected: selectedPaymentMethod == 'apple',
                onTap: () {
                  final analyticsService = ref.read(analyticsServiceProvider);
                  analyticsService.logCustomEvent(
                      eventName: 'apple_pay_option_selected(Apple Payment Page)',
                      parameters: {
                        'screen': 'Payment_page',
                      });
                  if (_isMounted && !_isDisposing) {
                    _safeStateUpdate(() {
                      ref.read(selectedPaymentMethodProvider.notifier).state = 'apple';
                    });
                  }
                },
              ),
            if (isInitialized) const SizedBox(height: 12),
            PaymentMethodCard(
              icon: Icons.credit_card_rounded,
              title: 'Credit/Debit Card',
              isSelected: selectedPaymentMethod == 'stripe',
              onTap: () {
                final analyticsService = ref.read(analyticsServiceProvider);
                analyticsService.logCustomEvent(
                    eventName: 'stripe_pay_option_selected(Apple Payment Page)',
                    parameters: {
                      'screen': 'Payment_page',
                    });
                if (_isMounted && !_isDisposing) {
                  _safeStateUpdate(() {
                    ref.read(selectedPaymentMethodProvider.notifier).state = 'stripe';
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}