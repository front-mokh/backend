import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

class ApiService {
  late final Dio _dio;
  String? _token;
  String? _socketId;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static String errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }

      final message = data['message'];
      if (message != null) return message.toString();
    }

    final message = error.error?.toString();
    if (message != null &&
        message.isNotEmpty &&
        !message.startsWith('DioException')) {
      return message;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'La connexion a expiré. Vérifiez votre internet puis réessayez.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
    }

    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  ApiService._internal() {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://72.62.20.218:8009/api';
    _dio = Dio(
      BaseOptions(
        baseUrl: apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          if (_socketId != null) {
            options.headers['X-Socket-ID'] = _socketId;
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          final msg = ApiService.errorMessage(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: msg,
            ),
          );
        },
      ),
    );
  }

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  void setSocketId(String? socketId) => _socketId = socketId;

  String? get token => _token;

  // ─── WebSocket Auth ───────────────────────────────────────

  Future<Map<String, dynamic>> authorizePusherChannel(
    String socketId,
    String channelName,
  ) async {
    final response = await _dio.post(
      '/broadcasting/auth',
      data: {'socket_id': socketId, 'channel_name': channelName},
    );
    return response.data;
  }

  String? getToken() => _token;

  // ─── Auth ──────────────────────────────────────────────────

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<SignupResponse> signup(
    String email,
    String password,
    String type,
  ) async {
    final response = await _dio.post(
      '/signup',
      data: {'email': email, 'password': password, 'type': type},
    );
    return SignupResponse.fromJson(response.data);
  }

  Future<void> logout() async {
    await _dio.post('/logout');
  }

  Future<void> resendVerificationEmail() async {
    await _dio.post('/email/verification-notification');
  }

  Future<User> getProfile() async {
    final response = await _dio.get('/user');
    return User.fromJson(response.data);
  }

  // ─── Onboarding / Metadata ─────────────────────────────────

  Future<List<Category>> getCategories() async {
    final response = await _dio.get('/categories');
    return (response.data as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Industry>> getIndustries() async {
    final response = await _dio.get('/industries');
    return (response.data as List).map((e) => Industry.fromJson(e)).toList();
  }

  Future<List<PlatformModel>> getPlatforms() async {
    final response = await _dio.get('/platforms');
    return (response.data as List)
        .map((e) => PlatformModel.fromJson(e))
        .toList();
  }

  Future<List<DeliverableType>> getDeliverableTypes() async {
    final response = await _dio.get('/deliverable-types');
    return (response.data as List)
        .map((e) => DeliverableType.fromJson(e))
        .toList();
  }

  Future<List<InfluencerTier>> getInfluencerTiers() async {
    final response = await _dio.get('/influencer-tiers');
    return (response.data as List)
        .map((e) => InfluencerTier.fromJson(e))
        .toList();
  }

  // ─── Creator Profile Onboarding ────────────────────────────

  Future<CreatorProfile> storeCreatorProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? nickname,
    String? bio,
    String? profilePicturePath,
    required List<String> links,
    required List<int> categories,
  }) async {
    final formData = FormData.fromMap({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'nickname': ?nickname,
      'bio': ?bio,
      if (profilePicturePath != null)
        'profile_picture': await MultipartFile.fromFile(
          profilePicturePath,
          filename: profilePicturePath.split('/').last,
        ),
    });

    for (int i = 0; i < links.length; i++) {
      formData.fields.add(MapEntry('links[$i]', links[i]));
    }
    for (int i = 0; i < categories.length; i++) {
      formData.fields.add(MapEntry('categories[$i]', categories[i].toString()));
    }

    final response = await _dio.post('/onboarding/creator', data: formData);
    return CreatorProfile.fromJson(response.data);
  }

  // ─── Brand Profile Onboarding ──────────────────────────────

  Future<BrandProfile> storeBrandProfile({
    required String name,
    required String phone,
    required String location,
    String? description,
    String? website,
    String? logoPath,
    required List<String> links,
    required List<int> industries,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'phone': phone,
      'location': location,
      'description': ?description,
      'website': ?website,
      if (logoPath != null)
        'logo': await MultipartFile.fromFile(
          logoPath,
          filename: logoPath.split('/').last,
        ),
    });

    for (int i = 0; i < links.length; i++) {
      formData.fields.add(MapEntry('links[$i]', links[i]));
    }
    for (int i = 0; i < industries.length; i++) {
      formData.fields.add(MapEntry('industries[$i]', industries[i].toString()));
    }

    final response = await _dio.post('/onboarding/brand', data: formData);
    return BrandProfile.fromJson(response.data);
  }

  // ─── Announcements ────────────────────────────────────────

  Future<List<Announcement>> getMyAnnouncements() async {
    final response = await _dio.get(
      '/announcements',
      queryParameters: {'my_projects': '1'},
    );
    return (response.data as List)
        .map((e) => Announcement.fromJson(e))
        .toList();
  }

  Future<List<Announcement>> getOpenAnnouncements({
    int? categoryId,
    double? minBudget,
    int? influencerTierId,
  }) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (minBudget != null) params['min_budget'] = minBudget.toString();
    if (influencerTierId != null) {
      params['influencer_tier_id'] = influencerTierId.toString();
    }

    final response = await _dio.get('/announcements', queryParameters: params);
    return (response.data as List)
        .map((e) => Announcement.fromJson(e))
        .toList();
  }

  Future<Announcement> getAnnouncement(int id) async {
    final response = await _dio.get('/announcements/$id');
    return Announcement.fromJson(response.data);
  }

  Future<Announcement> createAnnouncement({
    required int categoryId,
    required String title,
    required String description,
    required double budgetMin,
    required double budgetMax,
    required String deadline,
    String? deliveryDate,
    int? duration,
    String? targetAudience,
    String? requirements,
    int? minFollowers,
    int? influencerTierId,
    String? thumbnailPath,
    String? attachmentPath,
    List<int>? platforms,
    List<Map<String, int>>? deliverables,
  }) async {
    final formData = FormData.fromMap({
      'category_id': categoryId.toString(),
      'title': title,
      'description': description,
      'budget_min': budgetMin.toString(),
      'budget_max': budgetMax.toString(),
      'deadline': deadline,
      'delivery_date': ?deliveryDate,
      if (duration != null) 'duration': duration.toString(),
      'target_audience': ?targetAudience,
      'requirements': ?requirements,
      if (minFollowers != null) 'min_followers': minFollowers.toString(),
      if (influencerTierId != null)
        'influencer_tier_id': influencerTierId.toString(),
      if (thumbnailPath != null)
        'thumbnail': await MultipartFile.fromFile(
          thumbnailPath,
          filename: thumbnailPath.split('/').last,
        ),
      if (attachmentPath != null)
        'attachment': await MultipartFile.fromFile(
          attachmentPath,
          filename: attachmentPath.split('/').last,
        ),
    });

    if (platforms != null) {
      for (int i = 0; i < platforms.length; i++) {
        formData.fields.add(MapEntry('platforms[$i]', platforms[i].toString()));
      }
    }

    if (deliverables != null) {
      for (int i = 0; i < deliverables.length; i++) {
        formData.fields.add(
          MapEntry('deliverables[$i][id]', deliverables[i]['id'].toString()),
        );
        formData.fields.add(
          MapEntry(
            'deliverables[$i][quantity]',
            deliverables[i]['quantity'].toString(),
          ),
        );
      }
    }

    final response = await _dio.post('/announcements', data: formData);
    return Announcement.fromJson(response.data);
  }

  Future<Announcement> updateAnnouncement(
    int id, {
    required int categoryId,
    required String title,
    required String description,
    required double budgetMin,
    required double budgetMax,
    required String deadline,
    String? deliveryDate,
    int? duration,
    String? targetAudience,
    String? requirements,
    int? minFollowers,
    int? influencerTierId,
    String? thumbnailPath,
    String? attachmentPath,
    List<int>? platforms,
    List<Map<String, int>>? deliverables,
  }) async {
    final formData = FormData.fromMap({
      '_method': 'PUT',
      'category_id': categoryId.toString(),
      'title': title,
      'description': description,
      'budget_min': budgetMin.toString(),
      'budget_max': budgetMax.toString(),
      'deadline': deadline,
      'delivery_date': ?deliveryDate,
      if (duration != null) 'duration': duration.toString(),
      'target_audience': ?targetAudience,
      'requirements': ?requirements,
      if (minFollowers != null) 'min_followers': minFollowers.toString(),
      if (influencerTierId != null)
        'influencer_tier_id': influencerTierId.toString(),
    });

    if (thumbnailPath != null && !thumbnailPath.startsWith('http')) {
      formData.files.add(
        MapEntry(
          'thumbnail',
          await MultipartFile.fromFile(
            thumbnailPath,
            filename: thumbnailPath.split('/').last,
          ),
        ),
      );
    }

    if (attachmentPath != null && !attachmentPath.startsWith('http')) {
      formData.files.add(
        MapEntry(
          'attachment',
          await MultipartFile.fromFile(
            attachmentPath,
            filename: attachmentPath.split('/').last,
          ),
        ),
      );
    }

    if (platforms != null && platforms.isNotEmpty) {
      for (int i = 0; i < platforms.length; i++) {
        formData.fields.add(MapEntry('platforms[$i]', platforms[i].toString()));
      }
    } else {
      formData.fields.add(const MapEntry('platforms[]', ''));
    }

    if (deliverables != null && deliverables.isNotEmpty) {
      for (int i = 0; i < deliverables.length; i++) {
        formData.fields.add(
          MapEntry('deliverables[$i][id]', deliverables[i]['id'].toString()),
        );
        formData.fields.add(
          MapEntry(
            'deliverables[$i][quantity]',
            deliverables[i]['quantity'].toString(),
          ),
        );
      }
    } else {
      formData.fields.add(const MapEntry('deliverables[]', ''));
    }

    final response = await _dio.post('/announcements/$id', data: formData);
    return Announcement.fromJson(response.data);
  }

  Future<void> deleteAnnouncement(int id) async {
    await _dio.delete('/announcements/$id');
  }

  Future<Announcement> closeAnnouncement(int id) async {
    final response = await _dio.post('/announcements/$id/close');
    return Announcement.fromJson(response.data);
  }

  // ─── Applications ──────────────────────────────────────────

  Future<List<Application>> getApplications(
    int announcementId, {
    String? status,
  }) async {
    final params = <String, dynamic>{
      'announcement_id': announcementId.toString(),
    };
    if (status != null && status != 'all') params['status'] = status;
    final response = await _dio.get('/applications', queryParameters: params);
    return (response.data as List).map((e) => Application.fromJson(e)).toList();
  }

  Future<Application> updateApplicationStatus(int id, String status) async {
    final response = await _dio.post('/applications/$id/$status');
    return Application.fromJson(response.data);
  }

  Future<Application> acceptApplication(int id) async {
    final response = await _dio.post('/applications/$id/accept');
    return Application.fromJson(response.data);
  }

  Future<Application> rejectApplication(int id) async {
    final response = await _dio.post('/applications/$id/reject');
    return Application.fromJson(response.data);
  }

  Future<Application> applyToAnnouncement(
    int announcementId,
    String message,
    double proposedBudget,
  ) async {
    final response = await _dio.post(
      '/announcements/$announcementId/apply',
      data: {'message': message, 'proposed_budget': proposedBudget},
    );
    return Application.fromJson(response.data);
  }

  Future<List<Application>> getMyApplications() async {
    final response = await _dio.get('/applications');
    return (response.data as List).map((e) => Application.fromJson(e)).toList();
  }

  // ─── Collaborations ───────────────────────────────────────

  Future<List<Collaboration>> getCollaborations({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status != 'all') params['status'] = status;
    final response = await _dio.get('/collaborations', queryParameters: params);
    return (response.data as List)
        .map((e) => Collaboration.fromJson(e))
        .toList();
  }

  Future<Collaboration> getCollaboration(int id) async {
    final response = await _dio.get('/collaborations/$id');
    return Collaboration.fromJson(response.data);
  }

  Future<Collaboration> updateCollaborationStatus(int id, String status) async {
    final response = await _dio.patch(
      '/collaborations/$id/status',
      data: {'status': status},
    );
    return Collaboration.fromJson(response.data);
  }

  Future<Collaboration> completeCollaboration(int id) async {
    final response = await _dio.post('/collaborations/$id/complete');
    return Collaboration.fromJson(response.data);
  }

  Future<Message> sendCollaborationMessage(int id, FormData formData) async {
    final response = await _dio.post(
      '/collaborations/$id/messages',
      data: formData,
    );
    return Message.fromJson(response.data);
  }

  Future<DeliverableSubmission> submitDeliverable(
    int id,
    FormData formData,
  ) async {
    final response = await _dio.post(
      '/collaborations/$id/submissions',
      data: formData,
    );
    return DeliverableSubmission.fromJson(response.data);
  }

  Future<DeliverableSubmission> updateSubmissionStatus(
    int id,
    String status, {
    String? feedback,
  }) async {
    final response = await _dio.patch(
      '/submissions/$id',
      data: {'status': status, 'feedback': ?feedback},
    );
    return DeliverableSubmission.fromJson(response.data);
  }

  Future<void> sendHeartbeat(int id) async {
    await _dio.post('/collaborations/$id/heartbeat');
  }

  Future<Map<String, dynamic>> markCollabAsRead(int id) async {
    final response = await _dio.post('/collaborations/$id/read');
    return Map<String, dynamic>.from(response.data);
  }

  // ─── Notifications ────────────────────────────────────────

  Future<NotificationsResponse> getNotifications({int page = 1}) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: {'page': page.toString()},
    );
    return NotificationsResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    final response = await _dio.get('/notifications/unread-count');
    return response.data;
  }

  Future<AppNotification> markNotificationAsRead(int id) async {
    final response = await _dio.post('/notifications/$id/read');
    return AppNotification.fromJson(response.data);
  }

  Future<void> markAllNotificationsAsRead() async {
    await _dio.post('/notifications/read-all');
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<void> deleteAllNotifications() async {
    await _dio.delete('/notifications/all');
  }

  Future<void> registerPushToken(String token) async {
    await _dio.post('/user/expo-push-token', data: {'token': token});
  }
}
