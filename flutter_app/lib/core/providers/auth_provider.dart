import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  User? _user;
  String? _token;
  bool _isLoading = true;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isEmailVerified => _user?.isEmailVerified ?? false;
  bool get isOnboarded => _user?.isOnboarded ?? false;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final storedToken = await _storage.getToken();
      final storedUserJson = await _storage.getUser();

      if (storedToken != null && storedUserJson != null) {
        _token = storedToken;
        _user = User.fromJson(storedUserJson);
        _api.setToken(storedToken);

        // Fetch the newest data before routing so onboarding state is not stale.
        await refreshUser();
        await PushNotificationService.instance.syncToken();
      }
    } catch (e) {
      debugPrint('Failed to load auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _api.login(email, password);

    _token = response.token;
    _user = response.user;
    _api.setToken(response.token);

    await Future.wait([
      _storage.saveToken(response.token),
      _storage.saveUser(response.user.toJson()),
    ]);

    // Fetch complete user data with profile relationships
    try {
      await refreshUser();
    } catch (e) {
      debugPrint('Failed to refresh user data after login: $e');
    }

    await PushNotificationService.instance.syncToken();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await PushNotificationService.instance.unregisterToken();
      await _api.logout();
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    } finally {
      _token = null;
      _user = null;
      _api.clearToken();
      await _storage.clearAll();
      notifyListeners();
    }
  }

  Future<void> resendVerificationEmail() async {
    await _api.resendVerificationEmail();
  }

  Future<User?> refreshUser({bool throwOnError = false}) async {
    try {
      final updatedUser = await _api.getProfile();
      _user = updatedUser;
      await _storage.saveUser(updatedUser.toJson());
      notifyListeners();
      return updatedUser;
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
      if (throwOnError) rethrow;
      return null;
    }
  }

  void setUser(User user) {
    _user = user;
    _storage.saveUser(user.toJson());
    notifyListeners();
  }
}
