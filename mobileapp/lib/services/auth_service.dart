import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();

  static Future<ApiResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    return ApiService.post(
      ApiConfig.register,
      body: {
        'full_name':        fullName,
        'email':            email,
        'phone':            phone,
        'password':         password,
        'confirm_password': confirmPassword,
      },
      requiresAuth: false,
    );
  }

  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    return ApiService.post(
      ApiConfig.login,
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );
  }

  static Future<ApiResponse> logout() async {
    final response = await ApiService.post(ApiConfig.logout);
    await ApiService.deleteToken();
    return response;
  }

  static Future<ApiResponse> getProfile() async {
    return ApiService.get(ApiConfig.profile);
  }

  static Future<ApiResponse> updateProfile({
    String? fullName,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    return ApiService.post(
      ApiConfig.profile,
      body: {
        if (fullName        != null) 'full_name':        fullName,
        if (phone           != null) 'phone':            phone,
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword     != null) 'new_password':     newPassword,
      },
    );
  }

  static Future<ApiResponse> forgotPassword(String email) async {
    return ApiService.post(
      ApiConfig.forgotPassword,
      body: {'email': email},
      requiresAuth: false,
    );
  }

  static Future<bool> isLoggedIn() => ApiService.hasToken();

  static Future<void> saveSessionData(String token, UserModel user) async {
    await ApiService.saveToken(token);
  }
}
