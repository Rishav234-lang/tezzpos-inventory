import 'package:dio/dio.dart';

String parseApiError(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['error']?.toString() ?? data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your network.';
      default:
        break;
    }
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) return 'Invalid email or password. Please try again.';
    if (statusCode == 403) return 'Access denied. Insufficient permissions.';
    if (statusCode == 404) return 'Resource not found.';
    if (statusCode == 422) return 'Invalid data provided.';
    if (statusCode != null) return 'Server error ($statusCode). Please try again.';
    return 'Network error. Please try again.';
  }
  final msg = error.toString();
  if (msg.contains('DioException') || msg.contains('SocketException') || msg.contains('Connection refused')) {
    return 'Cannot connect to server. Please check your network.';
  }
  return msg;
}
