import 'dart:io';
import 'package:flutter/material.dart';

class FeedbackAttachment {
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String? thumbnailUrl;

  FeedbackAttachment({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    this.thumbnailUrl,
  });

  factory FeedbackAttachment.fromJson(Map<String, dynamic> json) {
    return FeedbackAttachment(
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }
}

class DeviceInfo {
  final String? platform;
  final String? osVersion;
  final String? deviceModel;
  final String? screenSize;

  DeviceInfo({
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.screenSize,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'],
      osVersion: json['osVersion'],
      deviceModel: json['deviceModel'],
      screenSize: json['screenSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'osVersion': osVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (screenSize != null) 'screenSize': screenSize,
    };
  }

  static DeviceInfo getCurrentDeviceInfo() {
    return DeviceInfo(
      platform: Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown',
      osVersion: Platform.operatingSystemVersion,
      deviceModel: Platform.isAndroid ? 'Android Device' : 'iOS Device',
      screenSize: '${Platform.numberOfProcessors} cores',
    );
  }
}

class FeedbackMetadata {
  final String? pageUrl;
  final String? featurePath;
  final String? interactionFlow;
  final int? timeSpent;

  FeedbackMetadata({
    this.pageUrl,
    this.featurePath,
    this.interactionFlow,
    this.timeSpent,
  });

  factory FeedbackMetadata.fromJson(Map<String, dynamic> json) {
    return FeedbackMetadata(
      pageUrl: json['pageUrl'],
      featurePath: json['featurePath'],
      interactionFlow: json['interactionFlow'],
      timeSpent: json['timeSpent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pageUrl != null) 'pageUrl': pageUrl,
      if (featurePath != null) 'featurePath': featurePath,
      if (interactionFlow != null) 'interactionFlow': interactionFlow,
      if (timeSpent != null) 'timeSpent': timeSpent,
    };
  }
}

class AdminResponse {
  final String message;
  final String? respondedBy;
  final DateTime respondedAt;

  AdminResponse({
    required this.message,
    this.respondedBy,
    required this.respondedAt,
  });

  factory AdminResponse.fromJson(Map<String, dynamic> json) {
    return AdminResponse(
      message: json['message'] ?? '',
      respondedBy: json['respondedBy']?['name'] ?? json['respondedBy'],
      respondedAt: DateTime.parse(json['respondedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (respondedBy != null) 'respondedBy': respondedBy,
      'respondedAt': respondedAt.toIso8601String(),
    };
  }
}

class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final FeedbackType type;
  final FeedbackCategory category;
  final String title;
  final String description;
  final FeedbackPriority priority;
  final FeedbackStatus status;
  final String appVersion;
  final DeviceInfo deviceInfo;
  final List<FeedbackAttachment> attachments;
  final int? rating;
  final AdminResponse? adminResponse;
  final List<String> tags;
  final FeedbackMetadata metadata;
  final int upvotes;
  final bool isAnonymous;
  final bool allowContact;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.appVersion,
    required this.deviceInfo,
    this.attachments = const [],
    this.rating,
    this.adminResponse,
    this.tags = const [],
    required this.metadata,
    this.upvotes = 0,
    this.isAnonymous = false,
    this.allowContact = true,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is String ? json['userId'] : json['userId']?['_id'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      type: FeedbackType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => FeedbackType.general,
      ),
      category: FeedbackCategory.values.firstWhere(
            (e) => e.name == json['category'],
        orElse: () => FeedbackCategory.other,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: FeedbackPriority.values.firstWhere(
            (e) => e.name == json['priority'],
        orElse: () => FeedbackPriority.medium,
      ),
      status: FeedbackStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      appVersion: json['appVersion'] ?? '1.0.0',
      deviceInfo: json['deviceInfo'] != null
          ? DeviceInfo.fromJson(json['deviceInfo'])
          : DeviceInfo(),
      attachments: (json['attachments'] as List?)
          ?.map((e) => FeedbackAttachment.fromJson(e))
          .toList() ?? [],
      rating: json['rating'],
      adminResponse: json['adminResponse'] != null
          ? AdminResponse.fromJson(json['adminResponse'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      metadata: json['metadata'] != null
          ? FeedbackMetadata.fromJson(json['metadata'])
          : FeedbackMetadata(), // Removed const
      upvotes: json['upvotes'] ?? 0,
      isAnonymous: json['isAnonymous'] ?? false,
      allowContact: json['allowContact'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.name,
      'category': category.name,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo.toJson(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      if (rating != null) 'rating': rating,
      if (adminResponse != null) 'adminResponse': adminResponse!.toJson(),
      'tags': tags,
      'metadata': metadata.toJson(),
      'upvotes': upvotes,
      'isAnonymous': isAnonymous,
      'allowContact': allowContact,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    FeedbackType? type,
    FeedbackCategory? category,
    String? title,
    String? description,
    FeedbackPriority? priority,
    FeedbackStatus? status,
    String? appVersion,
    DeviceInfo? deviceInfo,
    List<FeedbackAttachment>? attachments,
    int? rating,
    AdminResponse? adminResponse,
    List<String>? tags,
    FeedbackMetadata? metadata,
    int? upvotes,
    bool? isAnonymous,
    bool? allowContact,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      appVersion: appVersion ?? this.appVersion,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      attachments: attachments ?? this.attachments,
      rating: rating ?? this.rating,
      adminResponse: adminResponse ?? this.adminResponse,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      upvotes: upvotes ?? this.upvotes,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      allowContact: allowContact ?? this.allowContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

enum FeedbackType {
  bug('Bug'),
  feature_request('Feature Request'),
  improvement('Improvement'),
  general('General'),
  complaint('Complaint');

  final String displayName;
  const FeedbackType(this.displayName);

  String get icon {
    switch (this) {
      case FeedbackType.bug:
        return '🐛';
      case FeedbackType.feature_request:
        return '✨';
      case FeedbackType.improvement:
        return '📈';
      case FeedbackType.general:
        return '💬';
      case FeedbackType.complaint:
        return '⚠️';
    }
  }
}

enum FeedbackCategory {
  ui_ux('UI/UX'),
  performance('Performance'),
  functionality('Functionality'),
  content('Content'),
  pricing('Pricing'),
  other('Other');

  final String displayName;
  const FeedbackCategory(this.displayName);
}

enum FeedbackPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String displayName;
  const FeedbackPriority(this.displayName);

  Color get color {
    switch (this) {
      case FeedbackPriority.low:
        return Colors.green;
      case FeedbackPriority.medium:
        return Colors.blue;
      case FeedbackPriority.high:
        return Colors.orange;
      case FeedbackPriority.critical:
        return Colors.red;
    }
  }
}

enum FeedbackStatus {
  pending('Pending'),
  in_review('In Review'),
  in_progress('In Progress'),
  resolved('Resolved'),
  wont_fix('Won\'t Fix'),
  duplicate('Duplicate');

  final String displayName;
  const FeedbackStatus(this.displayName);

  Color get color {
    switch (this) {
      case FeedbackStatus.pending:
        return Colors.grey;
      case FeedbackStatus.in_review:
        return Colors.blue;
      case FeedbackStatus.in_progress:
        return Colors.orange;
      case FeedbackStatus.resolved:
        return Colors.green;
      case FeedbackStatus.wont_fix:
        return Colors.red;
      case FeedbackStatus.duplicate:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case FeedbackStatus.pending:
        return Icons.access_time;
      case FeedbackStatus.in_review:
        return Icons.remove_red_eye;
      case FeedbackStatus.in_progress:
        return Icons.build;
      case FeedbackStatus.resolved:
        return Icons.check_circle;
      case FeedbackStatus.wont_fix:
        return Icons.block;
      case FeedbackStatus.duplicate:
        return Icons.content_copy;
    }
  }
}

extension FeedbackTypeExtension on FeedbackType {
  Color get color {
    switch (this) {
      case FeedbackType.bug:
        return Colors.red;
      case FeedbackType.feature_request:
        return Colors.green;
      case FeedbackType.improvement:
        return Colors.blue;
      case FeedbackType.general:
        return Colors.purple;
      case FeedbackType.complaint:
        return Colors.orange;
    }
  }
}

extension FeedbackStatusExtension on FeedbackStatus {
  Color get color {
    switch (this) {
      case FeedbackStatus.pending:
        return Colors.grey;
      case FeedbackStatus.in_review:
        return Colors.blue;
      case FeedbackStatus.in_progress:
        return Colors.orange;
      case FeedbackStatus.resolved:
        return Colors.green;
      case FeedbackStatus.wont_fix:
        return Colors.red;
      case FeedbackStatus.duplicate:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case FeedbackStatus.pending:
        return Icons.access_time;
      case FeedbackStatus.in_review:
        return Icons.remove_red_eye;
      case FeedbackStatus.in_progress:
        return Icons.build;
      case FeedbackStatus.resolved:
        return Icons.check_circle;
      case FeedbackStatus.wont_fix:
        return Icons.block;
      case FeedbackStatus.duplicate:
        return Icons.content_copy;
    }
  }
}