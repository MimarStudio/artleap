import 'image_model.dart';

class UserProfileModel {
  final bool success;
  final String message;
  final User user;

  UserProfileModel({
    required this.success,
    required this.message,
    required this.user,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': user.toJson(),
    };
  }
}

class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final List<String> favorites;
  final String profilePic;
  final int dailyCredits;
  final bool isSubscribed;
  final List<Images> images;
  final List<dynamic> followers;
  final List<Following> following;
  final String createdAt;
  final int V;
  final DateTime? lastCreditReset;
  final List<String> hiddenNotifications;
  final String? currentSubscription;
  final String subscriptionStatus;
  final String planName;
  final String planType;
  final int totalCredits;
  final int usedImageCredits;
  final int usedPromptCredits;
  final int imageGenerationCredits;
  final int promptGenerationCredits;
  final bool hasActiveTrial;
  final List<dynamic> paymentMethods;
  final bool watermarkEnabled;
  final int? v;
  final int rewardDailyCount;
  final int rewardTotalCount;
  final DateTime? rewardLastRewardDate;
  final PrivacyPolicyAcceptance? privacyPolicyAccepted;
  final UserInterests? interests;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.favorites,
    required this.profilePic,
    required this.dailyCredits,
    required this.isSubscribed,
    required this.images,
    required this.followers,
    required this.following,
    required this.createdAt,
    required this.V,
    this.lastCreditReset,
    required this.hiddenNotifications,
    this.currentSubscription,
    required this.subscriptionStatus,
    required this.planName,
    required this.planType,
    required this.totalCredits,
    required this.usedImageCredits,
    required this.usedPromptCredits,
    required this.imageGenerationCredits,
    required this.promptGenerationCredits,
    required this.hasActiveTrial,
    required this.paymentMethods,
    required this.watermarkEnabled,
    this.v,
    this.rewardDailyCount = 0,
    this.rewardTotalCount = 0,
    this.rewardLastRewardDate,
    this.privacyPolicyAccepted,
    this.interests,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? "",
      username: json['username'] is String ? json['username'] as String : "",
      email: json['email'] ?? "",
      password: json['password'] ?? "",
      favorites: List.castFrom<dynamic, String>(json['favorites'] ?? []),
      profilePic: json['profilePic'] ?? "",
      dailyCredits: json['dailyCredits'] ?? 4,
      isSubscribed: json['isSubscribed'] ?? false,
      images: List.from(json['images'] ?? []).map((e) => Images.fromJson(e ?? {})).toList(),
      followers: List.castFrom<dynamic, dynamic>(json['followers'] ?? []),
      following: List.from(json['following'] ?? []).map((e) => Following.fromJson(e ?? {})).toList(),
      createdAt: json['createdAt'] ?? "",
      V: json['__v'] ?? 0,
      lastCreditReset: json['lastCreditReset'] != null ? DateTime.parse(json['lastCreditReset']) : null,
      hiddenNotifications: List.castFrom<dynamic, String>(json['hiddenNotifications'] ?? []),
      currentSubscription: json['currentSubscription']?.toString() ?? "",
      subscriptionStatus: json['subscriptionStatus'] ?? 'none',
      planName: json['planName'] ?? 'Free',
      planType: json['planType'] ?? 'free',
      totalCredits: json['totalCredits'] ?? 4,
      usedImageCredits: json['usedImageCredits'] ?? 0,
      usedPromptCredits: json['usedPromptCredits'] ?? 0,
      imageGenerationCredits: json['imageGenerationCredits'] ?? 0,
      promptGenerationCredits: json['promptGenerationCredits'] ?? 0,
      hasActiveTrial: json['hasActiveTrial'] ?? false,
      paymentMethods: List.castFrom<dynamic, dynamic>(json['paymentMethods'] ?? []),
      watermarkEnabled: json['watermarkEnabled'] ?? true,
      v: json['__v'],
      rewardDailyCount: json['rewardCount']?['dailyCount'] ?? 0,
      rewardTotalCount: json['rewardCount']?['totalCount'] ?? 0,
      rewardLastRewardDate: json['rewardCount']?['lastRewardDate'] != null ? DateTime.parse(json['rewardCount']['lastRewardDate']) : null,
      privacyPolicyAccepted: json['privacyPolicyAccepted'] != null
          ? PrivacyPolicyAcceptance.fromJson(json['privacyPolicyAccepted'])
          : null,
      interests: json['interests'] != null
          ? UserInterests.fromJson(json['interests'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['_id'] = id;
    data['username'] = username;
    data['email'] = email;
    data['password'] = password;
    data['favorites'] = favorites;
    data['profilePic'] = profilePic;
    data['dailyCredits'] = dailyCredits;
    data['isSubscribed'] = isSubscribed;
    data['images'] = images.map((e) => e.toJson()).toList();
    data['followers'] = followers;
    data['following'] = following.map((e) => e.toJson()).toList();
    data['createdAt'] = createdAt;
    data['__v'] = V;

    if (lastCreditReset != null) {
      data['lastCreditReset'] = lastCreditReset!.toIso8601String();
    }
    data['hiddenNotifications'] = hiddenNotifications;
    if (currentSubscription != null) {
      data['currentSubscription'] = currentSubscription;
    }
    data['subscriptionStatus'] = subscriptionStatus;
    data['planName'] = planName;
    data['planType'] = planType;
    data['totalCredits'] = totalCredits;
    data['usedImageCredits'] = usedImageCredits;
    data['usedPromptCredits'] = usedPromptCredits;
    data['imageGenerationCredits'] = imageGenerationCredits;
    data['promptGenerationCredits'] = promptGenerationCredits;
    data['hasActiveTrial'] = hasActiveTrial;
    data['paymentMethods'] = paymentMethods;
    data['watermarkEnabled'] = watermarkEnabled;
    if (v != null) {
      data['__v'] = v;
    }

    data['rewardCount'] = {
      'dailyCount': rewardDailyCount,
      'totalCount': rewardTotalCount,
      'lastRewardDate': rewardLastRewardDate?.toIso8601String(),
    };

    if (privacyPolicyAccepted != null) {
      data['privacyPolicyAccepted'] = privacyPolicyAccepted!.toJson();
    }
    if (interests != null) {
      data['interests'] = interests!.toJson();
    }

    return data;
  }

  User copyWith({
    int? rewardDailyCount,
    int? rewardTotalCount,
    DateTime? rewardLastRewardDate,
    PrivacyPolicyAcceptance? privacyPolicyAccepted,
    UserInterests? interests,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      password: password,
      favorites: favorites,
      profilePic: profilePic,
      dailyCredits: dailyCredits,
      isSubscribed: isSubscribed,
      images: images,
      followers: followers,
      following: following,
      createdAt: createdAt,
      V: V,
      lastCreditReset: lastCreditReset,
      hiddenNotifications: hiddenNotifications,
      currentSubscription: currentSubscription,
      subscriptionStatus: subscriptionStatus,
      planName: planName,
      planType: planType,
      totalCredits: totalCredits,
      usedImageCredits: usedImageCredits,
      usedPromptCredits: usedPromptCredits,
      imageGenerationCredits: imageGenerationCredits,
      promptGenerationCredits: promptGenerationCredits,
      hasActiveTrial: hasActiveTrial,
      paymentMethods: paymentMethods,
      watermarkEnabled: watermarkEnabled,
      v: v,
      rewardDailyCount: rewardDailyCount ?? this.rewardDailyCount,
      rewardTotalCount: rewardTotalCount ?? this.rewardTotalCount,
      rewardLastRewardDate: rewardLastRewardDate ?? this.rewardLastRewardDate,
      privacyPolicyAccepted: privacyPolicyAccepted ?? this.privacyPolicyAccepted,
      interests: interests ?? this.interests,
    );
  }
}

class Following {
  final String id;
  final String username;
  final String email;
  final String password;
  final List<String> favorites;
  final String profilePic;
  final int dailyCredits;
  final bool isSubscribed;
  final List<String> images;
  final List<String> followers;
  final List<dynamic> following;
  final String createdAt;
  final int V;

  Following({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.favorites,
    required this.profilePic,
    required this.dailyCredits,
    required this.isSubscribed,
    required this.images,
    required this.followers,
    required this.following,
    required this.createdAt,
    required this.V,
  });

  factory Following.fromJson(Map<String, dynamic> json) {
    return Following(
      id: json['_id'] ?? "",
      username: json['username'] is String ? json['username'] as String : "",
      email: json['email'] ?? "",
      password: json['password'] ?? "",
      favorites: List.castFrom<dynamic, String>(json['favorites'] ?? []),
      profilePic: json['profilePic'] ?? "",
      dailyCredits: json['dailyCredits'] ?? 0,
      isSubscribed: json['isSubscribed'] ?? false,
      images: List.castFrom<dynamic, String>(json['images'] ?? []),
      followers: List.castFrom<dynamic, String>(json['followers'] ?? []),
      following: List.castFrom<dynamic, dynamic>(json['following'] ?? []),
      createdAt: json['createdAt'] ?? "",
      V: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['_id'] = id;
    data['username'] = username;
    data['email'] = email;
    data['password'] = password;
    data['favorites'] = favorites;
    data['profilePic'] = profilePic;
    data['dailyCredits'] = dailyCredits;
    data['isSubscribed'] = isSubscribed;
    data['images'] = images;
    data['followers'] = followers;
    data['following'] = following;
    data['createdAt'] = createdAt;
    data['__v'] = V;
    return data;
  }
}

class PrivacyPolicyAcceptance {
  final bool accepted;
  final DateTime? acceptedAt;
  final String version;

  const PrivacyPolicyAcceptance({
    required this.accepted,
    this.acceptedAt,
    this.version = "1.0",
  });

  factory PrivacyPolicyAcceptance.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyAcceptance(
      accepted: json['accepted'] ?? false,
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      version: json['version'] ?? "1.0",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accepted': accepted,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'version': version,
    };
  }

  PrivacyPolicyAcceptance copyWith({
    bool? accepted,
    DateTime? acceptedAt,
    String? version,
  }) {
    return PrivacyPolicyAcceptance(
      accepted: accepted ?? this.accepted,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      version: version ?? this.version,
    );
  }
}

class UserInterests {
  final List<String> selected;
  final List<String> categories;
  final DateTime lastUpdated;

  const UserInterests({
    this.selected = const [],
    this.categories = const [],
    required this.lastUpdated,
  });

  factory UserInterests.fromJson(Map<String, dynamic> json) {
    return UserInterests(
      selected: List.castFrom<dynamic, String>(json['selected'] ?? []),
      categories: List.castFrom<dynamic, String>(json['categories'] ?? []),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selected': selected,
      'categories': categories,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UserInterests copyWith({
    List<String>? selected,
    List<String>? categories,
    DateTime? lastUpdated,
  }) {
    return UserInterests(
      selected: selected ?? this.selected,
      categories: categories ?? this.categories,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}