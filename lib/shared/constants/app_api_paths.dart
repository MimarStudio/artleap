class AppApiPaths {
  // Authentication paths
  static const String login = "login";
  static const String signup = "signup";
  static const String googleLogin = "googleLogin";
  static const String appleLogin = "appleLogin";
  static const String deleteAccount = "delete/";
  static const String forgotPassword = "forgot-password";

  // User paths
  static const getUsers = "getUsers";
  static const String getUserProData = "user/";
  static const String toggleFollow = "toggle-follow";
  static const String getUserFav = "favorites/";
  static const String togglefavourite = "toggle-favorite";
  static const String userCredits = "user/credits";
  static const String deductCredits = "user/deductCredits";

  // Image generation paths
  static const String generateImage = "freepikTxtToImg";
  static const String img2imgPath = "leonardoImgToImg";
  static const String leonardoTxt2ImgPath = "leonardoTxtToImg";
  static const String getUsersCreations = "all-images?page=";
  static const String deleteImage = "images/delete/";
  static const String reportImage = "images/";

  // Subscription paths
  static const String subscriptionsBasePath = "subscriptions/";
  static const String getSubscriptionPlans = "${subscriptionsBasePath}plans";
  static const String subscribe = "${subscriptionsBasePath}subscribe";
  static const String startTrial = "${subscriptionsBasePath}trial";
  static const String  cancelSubscription = "${subscriptionsBasePath}cancel";
  static const String getCurrentSubscription = "${subscriptionsBasePath}current";
  static const String checkGenerationLimits = "${subscriptionsBasePath}limits/";

  static const String createPaymentIntent = "${subscriptionsBasePath}create-payment-intent";
  // Other paths (from your example)
  static const passengers = "/api/v1/employees";
  static const getReqResUsers = "/users?page=2";
  static const updateImagePrivacy ="/images/";

  // Community Features - Likes
  static const String likesBasePath = "images/";
  static const String likeImage = "${likesBasePath}:imageId/like";
  static const String unlikeImage = "${likesBasePath}:imageId/like";
  static const String getImageLikes = "${likesBasePath}:imageId/likes";
  static const String getLikeCount = "${likesBasePath}:imageId/likes/count";
  static const String checkUserLike = "${likesBasePath}:imageId/likes/check";
  static const String getUserLikes = "users/likes";

  // Community Features - Comments
  static const String commentsBasePath = "images/";
  static const String addComment = "${commentsBasePath}:imageId/comments";
  static const String getImageComments = "${commentsBasePath}:imageId/comments";
  static const String updateComment = "comments/:commentId";
  static const String deleteComment = "comments/:commentId";
  static const String getCommentCount = "${commentsBasePath}:imageId/comments/count";
  static const String getUserComments = "users/comments";

  // Community Features - Saved Images
  static const String savedBasePath = "images/";
  static const String saveImage = "${savedBasePath}:imageId/save";
  static const String unsaveImage = "${savedBasePath}:imageId/save";
  static const String getUserSavedImages = "users/saved";
  static const String checkUserSave = "${savedBasePath}:imageId/save/check";
  static const String getSavedCount = "users/saved/count";

  static const String userPreferencesBase = "user-preferences/";
  static const String acceptPrivacyPolicy = "${userPreferencesBase}privacy-policy/accept";
  static const String updateInterests = "${userPreferencesBase}interests/update";
  static const String getUserPreferences = "${userPreferencesBase}preferences/";
  static const String checkPrivacyPolicyStatus = "${userPreferencesBase}privacy-policy/status/";

  static const String rewardedAds = "rewarded_ads/";
  static const String addRewardedCredits = "${rewardedAds}/rewarded-ad";
  static const String getRewardedCredits = "${rewardedAds}/credits-status";


  static const String enhancePrompt = "/enhance-prompt";

  static const String recordClick = '/clicks/record';
  static const String getBatchCounters = '/clicks/batch';
  static const String getUserStats = '/clicks/user';

  static const String submitFeedback = 'feedback/submit';
  static const String getFeedbackList = 'feedback';
  static const String getFeedbackById = 'feedback';
  static const String updateFeedback = 'feedback';
  static const String deleteFeedback = 'feedback';
  static const String addUpvote = 'feedback';
  static const String getUserFeedback = 'feedback/user';
  static const String getFeedbackStats = 'feedback/stats';
}