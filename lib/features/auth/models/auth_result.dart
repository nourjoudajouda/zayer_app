/// Result of an auth operation that may return a token.
sealed class AuthResult {
  const AuthResult();
}

/// Auth succeeded and user is logged in (token saved).
class AuthSuccess extends AuthResult {
  const AuthSuccess({required this.token});
  final String token;
}

/// Auth step succeeded but requires OTP verification (register/forgot).
class AuthRequiresOtp extends AuthResult {
  const AuthRequiresOtp({
    required this.phone,
    this.userId,
    this.mode = 'signup',
    this.devOtp,
  });
  final String phone;
  final int? userId;
  final String mode; // 'signup' | 'reset'
  /// When API returns OTP in response (e.g. in dev), pass it to show on OTP screen.
  final String? devOtp;
}

/// Auth failed with a message.
class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}
