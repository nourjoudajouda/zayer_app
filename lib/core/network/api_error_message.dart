import 'package:dio/dio.dart';

/// Turns Laravel / API errors into short, user-facing text (no raw Dio dumps).
String userFacingApiMessage(Object error) {
  if (error is DioException) {
    return _fromDio(error);
  }
  final s = error.toString();
  if (s.contains('SocketException') || s.contains('Connection refused')) {
    return 'Network error. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}

String _fromDio(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) {
      return msg.trim();
    }
    final errs = data['errors'];
    if (errs is Map) {
      final parts = <String>[];
      for (final entry in errs.entries) {
        final v = entry.value;
        if (v is List) {
          for (final x in v) {
            if (x != null && '$x'.trim().isNotEmpty) parts.add('$x'.trim());
          }
        } else if (v != null && '$v'.trim().isNotEmpty) {
          parts.add('$v'.trim());
        }
      }
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
    }
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Request timed out. Try again.';
    case DioExceptionType.connectionError:
      return 'Could not reach the server. Check your connection.';
    default:
      break;
  }
  final code = e.response?.statusCode;
  if (code == 401) {
    return 'Please sign in again.';
  }
  if (code == 422) {
    return 'Please check the highlighted fields.';
  }
  return 'Something went wrong. Please try again.';
}
