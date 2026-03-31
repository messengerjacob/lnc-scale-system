class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final String? details;

  factory ApiException.fromJson(int statusCode, Map<String, dynamic> json) {
    return ApiException(
      statusCode: statusCode,
      code:    json['code']    as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'An unexpected error occurred',
      details: json['details'] as String?,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $code — $message';
}
