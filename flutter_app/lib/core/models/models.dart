// All data models for the influencer marketplace app

// ─── User Types ──────────────────────────────────────────────

enum UserType { brand, creator }

UserType userTypeFromString(String s) =>
    s == 'brand' ? UserType.brand : UserType.creator;

String userTypeToString(UserType t) =>
    t == UserType.brand ? 'brand' : 'creator';

// ─── User ────────────────────────────────────────────────────

class User {
  final int id;
  final String email;
  final UserType type;
  final String createdAt;
  final String updatedAt;
  final String? emailVerifiedAt;
  final String? onboardingCompletedAt;
  final String? profileVerifiedAt;
  final BrandProfile? brandProfile;
  final CreatorProfile? creatorProfile;
  final List<SocialLink>? socialLinks;
  final List<Category>? categories;

  User({
    required this.id,
    required this.email,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.emailVerifiedAt,
    this.onboardingCompletedAt,
    this.profileVerifiedAt,
    this.brandProfile,
    this.creatorProfile,
    this.socialLinks,
    this.categories,
  });

  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isOnboarded => onboardingCompletedAt != null;
  bool get isBrand => type == UserType.brand;
  bool get isCreator => type == UserType.creator;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      type: userTypeFromString(json['type'] as String),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      onboardingCompletedAt: json['onboarding_completed_at'] as String?,
      profileVerifiedAt: json['profile_verified_at'] as String?,
      brandProfile: json['brand_profile'] != null
          ? BrandProfile.fromJson(json['brand_profile'])
          : null,
      creatorProfile: json['creator_profile'] != null
          ? CreatorProfile.fromJson(json['creator_profile'])
          : null,
      socialLinks: (json['social_links'] as List<dynamic>?)
          ?.map((e) => SocialLink.fromJson(e))
          .toList(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'type': userTypeToString(type),
    'created_at': createdAt,
    'updated_at': updatedAt,
    'email_verified_at': emailVerifiedAt,
    'onboarding_completed_at': onboardingCompletedAt,
    'profile_verified_at': profileVerifiedAt,
    'brand_profile': brandProfile?.toJson(),
    'creator_profile': creatorProfile?.toJson(),
    'social_links': socialLinks?.map((e) => e.toJson()).toList(),
    'categories': categories?.map((e) => e.toJson()).toList(),
  };
}

// ─── Profiles ────────────────────────────────────────────────

class BrandProfile {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String location;
  final String? description;
  final String? website;
  final String? logo;
  final List<Industry>? industries;

  BrandProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.location,
    this.description,
    this.website,
    this.logo,
    this.industries,
  });

  factory BrandProfile.fromJson(Map<String, dynamic> json) {
    return BrandProfile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String?,
      website: json['website'] as String?,
      logo: json['logo'] as String?,
      industries: (json['industries'] as List<dynamic>?)
          ?.map((e) => Industry.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'phone': phone,
    'location': location,
    'description': description,
    'website': website,
    'logo': logo,
    'industries': industries?.map((e) => e.toJson()).toList(),
  };
}

class CreatorProfile {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String? nickname;
  final String? bio;
  final String? profilePicture;
  final String phone;

  CreatorProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.bio,
    this.profilePicture,
    required this.phone,
  });

  String get fullName => '$firstName $lastName';

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    return CreatorProfile(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      nickname: json['nickname'] as String?,
      bio: json['bio'] as String?,
      profilePicture: json['profile_picture'] as String?,
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'first_name': firstName,
    'last_name': lastName,
    'nickname': nickname,
    'bio': bio,
    'profile_picture': profilePicture,
    'phone': phone,
  };
}

// ─── Social Links ────────────────────────────────────────────

class SocialLink {
  final int id;
  final String platform;
  final String url;
  final bool isVerified;

  SocialLink({
    required this.id,
    required this.platform,
    required this.url,
    required this.isVerified,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
    id: json['id'] as int,
    platform: json['platform'] as String? ?? '',
    url: json['url'] as String? ?? '',
    isVerified: json['is_verified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'url': url,
    'is_verified': isVerified,
  };
}

// ─── Category & Industry ─────────────────────────────────────

class Category {
  final int id;
  final String name;
  final String? description;

  Category({required this.id, required this.name, this.description});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}

class Industry {
  final int id;
  final String name;
  final String? description;

  Industry({required this.id, required this.name, this.description});

  factory Industry.fromJson(Map<String, dynamic> json) => Industry(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}

// ─── Platform & Deliverables ─────────────────────────────────

class PlatformModel {
  final int id;
  final String name;
  final String? iconName;

  PlatformModel({required this.id, required this.name, this.iconName});

  factory PlatformModel.fromJson(Map<String, dynamic> json) => PlatformModel(
    id: json['id'] as int,
    name: json['name'] as String,
    iconName: json['icon_name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
  };
}

class DeliverableType {
  final int id;
  final String name;
  final String? iconName;
  final int platformId;

  DeliverableType({
    required this.id,
    required this.name,
    this.iconName,
    required this.platformId,
  });

  factory DeliverableType.fromJson(Map<String, dynamic> json) =>
      DeliverableType(
        id: json['id'] as int,
        name: json['name'] as String,
        iconName: json['icon_name'] as String?,
        platformId: json['platform_id'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'platform_id': platformId,
  };
}

class InfluencerTier {
  final int id;
  final String name;
  final int? minFollowers;
  final int? maxFollowers;

  InfluencerTier({
    required this.id,
    required this.name,
    this.minFollowers,
    this.maxFollowers,
  });

  factory InfluencerTier.fromJson(Map<String, dynamic> json) => InfluencerTier(
    id: json['id'] as int,
    name: json['name'] as String,
    minFollowers: json['min_followers'] as int?,
    maxFollowers: json['max_followers'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'min_followers': minFollowers,
    'max_followers': maxFollowers,
  };
}

// ─── Announcement ────────────────────────────────────────────

class Announcement {
  final int id;
  final String title;
  final String description;
  final int? influencerTierId;
  final String? thumbnail;
  final String? attachment;
  final double budgetMin;
  final double budgetMax;
  final String deadline;
  final String? deliveryDate;
  final int? duration;
  final String? targetAudience;
  final String? requirements;
  final int? minFollowers;
  final String status;
  final String createdAt;
  final Category? category;
  final List<PlatformModel>? platforms;
  final List<DeliverableWithPivot>? deliverables;
  final InfluencerTier? influencerTier;
  final int? applicationsCount;
  final int? applicationsPendingCount;
  final int? applicationsAcceptedCount;
  final int? applicationsRejectedCount;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.influencerTierId,
    this.thumbnail,
    this.attachment,
    required this.budgetMin,
    required this.budgetMax,
    required this.deadline,
    this.deliveryDate,
    this.duration,
    this.targetAudience,
    this.requirements,
    this.minFollowers,
    required this.status,
    required this.createdAt,
    this.category,
    this.platforms,
    this.deliverables,
    this.influencerTier,
    this.applicationsCount,
    this.applicationsPendingCount,
    this.applicationsAcceptedCount,
    this.applicationsRejectedCount,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      influencerTierId: json['influencer_tier_id'] != null
          ? int.tryParse(json['influencer_tier_id'].toString())
          : null,
      thumbnail: json['thumbnail'] as String?,
      attachment: json['attachment'] as String?,
      budgetMin: double.tryParse(json['budget_min'].toString()) ?? 0.0,
      budgetMax: double.tryParse(json['budget_max'].toString()) ?? 0.0,
      deadline: json['deadline'] as String,
      deliveryDate: json['delivery_date'] as String?,
      duration: json['duration'] != null
          ? int.tryParse(json['duration'].toString())
          : null,
      targetAudience: json['target_audience'] as String?,
      requirements: json['requirements'] as String?,
      minFollowers: json['min_followers'] != null
          ? int.tryParse(json['min_followers'].toString())
          : null,
      status: json['status'] as String? ?? 'open',
      createdAt: json['created_at'] as String,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      platforms: (json['platforms'] as List<dynamic>?)
          ?.map((e) => PlatformModel.fromJson(e))
          .toList(),
      deliverables: (json['deliverables'] as List<dynamic>?)
          ?.map((e) => DeliverableWithPivot.fromJson(e))
          .toList(),
      influencerTier: json['influencer_tier'] != null
          ? InfluencerTier.fromJson(json['influencer_tier'])
          : null,
      applicationsCount: json['applications_count'] != null
          ? int.tryParse(json['applications_count'].toString())
          : null,
      applicationsPendingCount: json['applications_pending_count'] != null
          ? int.tryParse(json['applications_pending_count'].toString())
          : null,
      applicationsAcceptedCount: json['applications_accepted_count'] != null
          ? int.tryParse(json['applications_accepted_count'].toString())
          : null,
      applicationsRejectedCount: json['applications_rejected_count'] != null
          ? int.tryParse(json['applications_rejected_count'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'influencer_tier_id': influencerTierId,
    'thumbnail': thumbnail,
    'attachment': attachment,
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'deadline': deadline,
    'delivery_date': deliveryDate,
    'duration': duration,
    'target_audience': targetAudience,
    'requirements': requirements,
    'min_followers': minFollowers,
    'status': status,
    'created_at': createdAt,
  };
}

class DeliverableWithPivot {
  final int id;
  final String name;
  final String? iconName;
  final int platformId;
  final int quantity;

  DeliverableWithPivot({
    required this.id,
    required this.name,
    this.iconName,
    required this.platformId,
    required this.quantity,
  });

  factory DeliverableWithPivot.fromJson(Map<String, dynamic> json) =>
      DeliverableWithPivot(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
        name: json['name'] as String,
        iconName: json['icon_name'] as String?,
        platformId: json['platform_id'] != null
            ? int.tryParse(json['platform_id'].toString()) ?? 0
            : 0,
        quantity: json['pivot']?['quantity'] != null
            ? int.tryParse(json['pivot']!['quantity'].toString()) ?? 1
            : 1,
      );
}

// ─── Application ─────────────────────────────────────────────

class Application {
  final int id;
  final int announcementId;
  final int userId;
  final String message;
  final double proposedBudget;
  final String status;
  final String createdAt;
  final String updatedAt;
  final User? user;
  final Announcement? announcement;

  Application({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.message,
    required this.proposedBudget,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.announcement,
  });

  factory Application.fromJson(Map<String, dynamic> json) => Application(
    id: json['id'] as int,
    announcementId: json['announcement_id'] as int,
    userId: json['user_id'] as int,
    message: json['message'] as String,
    proposedBudget: double.tryParse(json['proposed_budget'].toString()) ?? 0.0,
    status: json['status'] as String,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    user: json['user'] != null ? User.fromJson(json['user']) : null,
    announcement: json['announcement'] != null
        ? Announcement.fromJson(json['announcement'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'announcement_id': announcementId,
    'user_id': userId,
    'message': message,
    'proposed_budget': proposedBudget,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

// ─── Collaboration & Messages ────────────────────────────────

class Message {
  final int id;
  final int collaborationId;
  final int senderId;
  final String? content;
  final String? attachment;
  final bool isRead;
  final String createdAt;
  final User? sender;

  Message({
    required this.id,
    required this.collaborationId,
    required this.senderId,
    this.content,
    this.attachment,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as int,
    collaborationId: json['collaboration_id'] as int,
    senderId: json['sender_id'] as int,
    content: json['content'] as String?,
    attachment: json['attachment'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    createdAt: json['created_at'] as String,
    sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'collaboration_id': collaborationId,
    'sender_id': senderId,
    'content': content,
    'attachment': attachment,
    'is_read': isRead,
    'created_at': createdAt,
  };
}

class DeliverableSubmission {
  final int id;
  final int collaborationId;
  final int deliverableTypeId;
  final String? url;
  final String? attachment;
  final String status;
  final String? feedback;
  final String createdAt;
  final DeliverableType? deliverableType;

  DeliverableSubmission({
    required this.id,
    required this.collaborationId,
    required this.deliverableTypeId,
    this.url,
    this.attachment,
    required this.status,
    this.feedback,
    required this.createdAt,
    this.deliverableType,
  });

  factory DeliverableSubmission.fromJson(Map<String, dynamic> json) =>
      DeliverableSubmission(
        id: json['id'] as int,
        collaborationId: json['collaboration_id'] as int,
        deliverableTypeId: json['deliverable_type_id'] as int,
        url: json['url'] as String?,
        attachment: json['attachment'] as String?,
        status: json['status'] as String,
        feedback: json['feedback'] as String?,
        createdAt: json['created_at'] as String,
        deliverableType:
            (json['deliverable_type'] ?? json['deliverableType']) != null
            ? DeliverableType.fromJson(
                json['deliverable_type'] ?? json['deliverableType'],
              )
            : null,
      );
}

class Collaboration {
  final int id;
  final int applicationId;
  final int announcementId;
  final int brandId;
  final int creatorId;
  final String status;
  final String startedAt;
  final String? completedAt;
  final String createdAt;
  final String? brandLastSeenAt;
  final String? creatorLastSeenAt;
  final String? brandLastReadAt;
  final String? creatorLastReadAt;
  final int? unreadCount;
  final Announcement? announcement;
  final User? brand;
  final User? creator;
  final Application? application;
  List<Message>? messages;
  List<DeliverableSubmission>? submissions;

  Collaboration({
    required this.id,
    required this.applicationId,
    required this.announcementId,
    required this.brandId,
    required this.creatorId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.brandLastSeenAt,
    this.creatorLastSeenAt,
    this.brandLastReadAt,
    this.creatorLastReadAt,
    this.unreadCount,
    this.announcement,
    this.brand,
    this.creator,
    this.application,
    this.messages,
    this.submissions,
  });

  factory Collaboration.fromJson(Map<String, dynamic> json) => Collaboration(
    id: json['id'] as int,
    applicationId: json['application_id'] as int,
    announcementId: json['announcement_id'] as int,
    brandId: json['brand_id'] as int,
    creatorId: json['creator_id'] as int,
    status: json['status'] as String,
    startedAt: json['started_at'] as String,
    completedAt: json['completed_at'] as String?,
    createdAt: json['created_at'] as String,
    brandLastSeenAt: json['brand_last_seen_at'] as String?,
    creatorLastSeenAt: json['creator_last_seen_at'] as String?,
    brandLastReadAt: json['brand_last_read_at'] as String?,
    creatorLastReadAt: json['creator_last_read_at'] as String?,
    unreadCount: json['unread_count'] as int?,
    announcement: json['announcement'] != null
        ? Announcement.fromJson(json['announcement'])
        : null,
    brand: json['brand'] != null ? User.fromJson(json['brand']) : null,
    creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
    application: json['application'] != null
        ? Application.fromJson(json['application'])
        : null,
    messages: (json['messages'] as List<dynamic>?)
        ?.map((e) => Message.fromJson(e))
        .toList(),
    submissions: (json['submissions'] as List<dynamic>?)
        ?.map((e) => DeliverableSubmission.fromJson(e))
        .toList(),
  );

  Collaboration copyWith({
    int? id,
    int? applicationId,
    int? announcementId,
    int? brandId,
    int? creatorId,
    String? status,
    String? startedAt,
    String? completedAt,
    String? createdAt,
    String? brandLastSeenAt,
    String? creatorLastSeenAt,
    String? brandLastReadAt,
    String? creatorLastReadAt,
    int? unreadCount,
    Announcement? announcement,
    User? brand,
    User? creator,
    Application? application,
    List<Message>? messages,
    List<DeliverableSubmission>? submissions,
  }) {
    return Collaboration(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      announcementId: announcementId ?? this.announcementId,
      brandId: brandId ?? this.brandId,
      creatorId: creatorId ?? this.creatorId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      brandLastSeenAt: brandLastSeenAt ?? this.brandLastSeenAt,
      creatorLastSeenAt: creatorLastSeenAt ?? this.creatorLastSeenAt,
      brandLastReadAt: brandLastReadAt ?? this.brandLastReadAt,
      creatorLastReadAt: creatorLastReadAt ?? this.creatorLastReadAt,
      unreadCount: unreadCount ?? this.unreadCount,
      announcement: announcement ?? this.announcement,
      brand: brand ?? this.brand,
      creator: creator ?? this.creator,
      application: application ?? this.application,
      messages: messages ?? this.messages,
      submissions: submissions ?? this.submissions,
    );
  }
}

// ─── Notifications ───────────────────────────────────────────

class AppNotification {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String createdAt;
  final String updatedAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRead => readAt != null;

  AppNotification copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? readAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        data: json['data'] as Map<String, dynamic>?,
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
}

class NotificationsResponse {
  final List<AppNotification> data;
  final int currentPage;
  final int lastPage;
  final int total;

  NotificationsResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) =>
      NotificationsResponse(
        data: (json['data'] as List<dynamic>)
            .map((e) => AppNotification.fromJson(e))
            .toList(),
        currentPage: json['current_page'] as int,
        lastPage: json['last_page'] as int,
        total: json['total'] as int,
      );
}

// ─── Auth Responses ──────────────────────────────────────────

class AuthResponse {
  final User user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    user: User.fromJson(json['user']),
    token: json['token'] as String,
  );
}

class SignupResponse {
  final String message;
  final User user;

  SignupResponse({required this.message, required this.user});

  factory SignupResponse.fromJson(Map<String, dynamic> json) => SignupResponse(
    message: json['message'] as String,
    user: User.fromJson(json['user']),
  );
}
