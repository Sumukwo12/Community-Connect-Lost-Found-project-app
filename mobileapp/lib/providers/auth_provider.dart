import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status   = AuthStatus.unknown;
  UserModel? _user;
  bool       _loading  = false;
  String?    _error;

  AuthStatus get status        => _status;
  UserModel? get user          => _user;
  bool       get isLoading     => _loading;
  String?    get error         => _error;
  bool       get isAuth        => _status == AuthStatus.authenticated;
  bool       get isUnknown     => _status == AuthStatus.unknown;

  // ─── Bootstrap ────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      await _fetchProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    final response = await AuthService.getProfile();
    if (response.success && response.data != null) {
      _user   = UserModel.fromJson(response.data as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } else if (response.isAuthError) {
      await ApiService.deleteToken();
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ─── Register ─────────────────────────────────────────────────────────────────
  Future<ApiResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    final response = await AuthService.register(
      fullName:        fullName,
      email:           email,
      phone:           phone,
      password:        password,
      confirmPassword: confirmPassword,
    );
    if (response.success && response.data != null) {
      final data  = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      _user       = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await ApiService.saveToken(token);
      _status = AuthStatus.authenticated;
      _error  = null;
    } else {
      _error = response.message;
    }
    _setLoading(false);
    return response;
  }

  // ─── Login ────────────────────────────────────────────────────────────────────
  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    final response = await AuthService.login(email: email, password: password);
    if (response.success && response.data != null) {
      final data  = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      _user       = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await ApiService.saveToken(token);
      _status = AuthStatus.authenticated;
      _error  = null;
    } else {
      _error = response.message;
    }
    _setLoading(false);
    return response;
  }

  // ─── Logout ───────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    await AuthService.logout();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    _error  = null;
    _setLoading(false);
  }

  // ─── Update Profile ───────────────────────────────────────────────────────────
  Future<ApiResponse> updateProfile({
    String? fullName,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    _setLoading(true);
    final response = await AuthService.updateProfile(
      fullName:        fullName,
      phone:           phone,
      currentPassword: currentPassword,
      newPassword:     newPassword,
    );
    if (response.success && response.data != null) {
      _user = UserModel.fromJson(response.data as Map<String, dynamic>);
    }
    _setLoading(false);
    return response;
  }

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
