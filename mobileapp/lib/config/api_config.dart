/// API Configuration for Community Connect
/// Change [baseUrl] to switch between environments.
class ApiConfig {
  ApiConfig._();

  /// If testing on a physical phone over Wi-Fi, use your PC's Wi-Fi IP (e.g. 192.168.x.x)
  static const String _lanUrl = 'http://192.168.3.104:8000';

  /// If testing on Android Emulator, use 10.0.2.2
  static const String _emulatorUrl = 'http://10.0.2.2:8000';

  /// Production cPanel URL for lost.strand.co.ke
  static const String _productionUrl = 'https://lost.strand.co.ke';

  /// Set the active baseUrl here:
  /// - Use _productionUrl for live deployment on lost.strand.co.ke
  /// - Use _lanUrl if testing locally on a physical Android phone over Wi-Fi
  /// - Use _emulatorUrl if testing locally on an Android Emulator
  static const String baseUrl = _productionUrl;

  // ─── Auth endpoints ──────────────────────────────────────────────────────────
  static const String register = '$baseUrl/auth/register.php';
  static const String login = '$baseUrl/auth/login.php';
  static const String logout = '$baseUrl/auth/logout.php';
  static const String profile = '$baseUrl/auth/profile.php';
  static const String forgotPassword = '$baseUrl/auth/forgot_password.php';

  // ─── Item endpoints ──────────────────────────────────────────────────────────
  static const String itemCreate = '$baseUrl/items/create.php';
  static const String itemList = '$baseUrl/items/list.php';
  static const String itemGet = '$baseUrl/items/get.php';
  static const String itemUpdate = '$baseUrl/items/update.php';
  static const String itemDelete = '$baseUrl/items/delete.php';
  static const String itemResolve = '$baseUrl/items/resolve.php';

  // ─── Category endpoints ──────────────────────────────────────────────────────
  static const String categoryList = '$baseUrl/categories/list.php';

  // ─── Message endpoints ───────────────────────────────────────────────────────
  static const String messageSend = '$baseUrl/messages/send.php';
  static const String messageList = '$baseUrl/messages/list.php';

  // ─── Report endpoints ─────────────────────────────────────────────────────────
  static const String reportCreate = '$baseUrl/reports/create.php';

  // ─── Timeouts ────────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
