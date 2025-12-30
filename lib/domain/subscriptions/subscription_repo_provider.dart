import 'package:Artleap.ai/domain/subscriptions/subscription_model.dart';
import 'package:Artleap.ai/domain/subscriptions/subscription_repo_impl.dart';
import 'package:Artleap.ai/domain/subscriptions/subscription_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Artleap.ai/domain/api_services/api_response.dart';
import '../../providers/watermark_provider.dart';
import '../base_repo/base.dart';
import '../payment/payment_service.dart';

final baseProvider = Provider<Base>((ref) => Base());

final subscriptionRepoProvider =
    Provider<SubscriptionRepoImpl>((ref) => SubscriptionRepoImpl());

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final repo = ref.read(subscriptionRepoProvider);
  return SubscriptionService(repo);
});

final paymentServiceProvider =
    Provider.family<PaymentService, String>((ref, userId) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  final base = ref.read(baseProvider);
  return PaymentService(subscriptionService, base, userId);
});

final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlanModel>>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  final response = await service.getSubscriptionPlans();
  if (response.status == Status.completed && response.data != null) {
    return response.data as List<SubscriptionPlanModel>;
  }
  throw Exception(response.message ?? 'Failed to fetch subscription plans');
});

final currentSubscriptionProvider =
    FutureProvider.family<UserSubscriptionModel?, String>((ref, userId) async {
  final service = ref.read(subscriptionServiceProvider);
  final response = await service.getCurrentSubscription(userId);
  if (response.status == Status.completed) {
    ref.read(watermarkProvider.notifier).initializeWatermarkState();
    return response.data;
  }
  return null;
});

final generationLimitsProvider =
    FutureProvider.family<GenerationLimitsModel, Map<String, String>>(
        (ref, params) async {
  final service = ref.read(subscriptionServiceProvider);
  final response = await service.checkGenerationLimits(
      params['userId']!, params['generationType']!);
  if (response.status == Status.completed && response.data != null) {
    ref.read(watermarkProvider.notifier).initializeWatermarkState();
    return response.data as GenerationLimitsModel;
  }
  throw Exception(response.message ?? 'Failed to fetch generation limits');
});

final cancelSubscriptionProvider =
    FutureProvider.family<ApiResponse, CancelSubscriptionParams>(
        (ref, params) async {
  final service = ref.read(subscriptionServiceProvider);
  return await service.cancelSubscription(
    params.userId,
    params.immediate,
  );
});

class CancelSubscriptionParams {
  final String userId;
  final bool immediate;

  CancelSubscriptionParams({
    required this.userId,
    required this.immediate,
  });
}
