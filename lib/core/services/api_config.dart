class ApiConfig {
  static const bool useFakeApi = false;

  static const String baseUrl = 'http://192.168.0.108:5000/api';

  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String deleteAccount = '$baseUrl/auth/account';
  static const String uploadWorkOrder = '$baseUrl/work-orders/upload';
  static const String myWorkOrders = '$baseUrl/work-orders/my';
  static const String addPhotosToExistingWorkOrder =
      '$baseUrl/work-orders/add-photos';
}
