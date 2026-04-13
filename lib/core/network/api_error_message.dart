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

/// Laravel 422 `errors` map: first message per field key (snake_case).
Map<String, String> validationErrorsFromDio(Object error) {
  if (error is! DioException) return const {};
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return const {};
  final errs = data['errors'];
  if (errs is! Map) return const {};
  final out = <String, String>{};
  for (final entry in errs.entries) {
    final key = entry.key.toString();
    final v = entry.value;
    String? first;
    if (v is List && v.isNotEmpty) {
      first = v.first?.toString().trim();
    } else if (v != null) {
      first = v.toString().trim();
    }
    if (first != null && first.isNotEmpty) {
      out[key] = first;
    }
  }
  return out;
}

bool _isGenericLaravelMessage(String? m) {
  if (m == null || m.isEmpty) return true;
  final t = m.toLowerCase();
  return t.contains('given data was invalid') ||
      t.contains('the given data was invalid') ||
      t == 'validation error';
}

String _fromDio(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
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
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty && !_isGenericLaravelMessage(msg)) {
      return msg.trim();
    }
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return 'Could not connect in time. Check your connection and try again.';
    case DioExceptionType.sendTimeout:
      return 'Upload timed out. Try a smaller photo, use Wi‑Fi, or try again.';
    case DioExceptionType.receiveTimeout:
      return 'The server took too long to respond. Try again.';
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
    return 'Please check your entries and try again.';
  }
  return 'Something went wrong. Please try again.';
}
