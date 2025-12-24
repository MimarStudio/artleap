class AppConstants {
  // Base URLs
  static const String artleapBaseUrl = "http://192.168.2.1:8000/api/";
  // static const String artleapBaseUrl = "http://43.205.54.198:8000/api/";
  static const String otherBaseUrl = "https://jsonplaceholder1.typicode.com";
  static const String reqresBaseUrl = "https://reqres.in/api/";

  // Image Generation APIs
  static const String textToImageUrl = "https://modelslab.com/api/v6/images/text2img";
  static const String imgToimgUrl = "https://api.stability.ai/v2beta/stable-image/generate/sd3";
  static const String generateHighQualityImage = "https://modelslab.com/api/v6/realtime/text2img";
  static const String freePikImageUrl = "https://api.freepik.com/v1/ai/text-to-image";
  static const String getModelsList = "https://modelslab.com/api/v4/dreambooth/model_list";

  // Subscription paths
  static const String subscriptionsBasePath = "subscriptions/";
  static const String getSubscriptionPlans = "${subscriptionsBasePath}plans";
  static const String subscribe = "${subscriptionsBasePath}subscribe";
  static const String startTrial = "${subscriptionsBasePath}trial";
  static const String cancelSubscription = "${subscriptionsBasePath}cancel";
  static const String getCurrentSubscription = "${subscriptionsBasePath}current";
  static const String checkGenerationLimits = "${subscriptionsBasePath}limits/";

  // API Keys
  static const String stableDefKey = "q888ISOb2v6zvmbLTb7tbSyiMrVfzZ3A8lQrp2yNaI55m5OYujQqPmlOGfuf";

  // Notification paths
  static const String notificationsBasePath = "notifications/";
  static const String getUserNotificationsPath = "${notificationsBasePath}user/";
  static const String markAsReadPath = notificationsBasePath;
  static const String deleteNotificationPath = notificationsBasePath;
  static const String createNotificationPath = notificationsBasePath;
  static const String markAllAsReadPath = "${notificationsBasePath}mark-all-read";
  static const String registerToken =  "${notificationsBasePath}register-token";

  // Notification types
  static const String generalNotificationType = "general";
  static const String userNotificationType = "user";

  // App Configuration
  static const Environment environment = Environment.development;
  static const ResponseMode responseMode = ResponseMode.real;
  static const String localDataStorageEnabled = "localDataStorageEnabled";
}

enum Environment { development, staging, production }

enum ResponseMode { mock, real }

String localDataStorageEnabled = "localDataStorageEnabled";
