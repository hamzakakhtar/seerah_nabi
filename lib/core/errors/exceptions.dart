/// Low-level exceptions thrown by data sources before mapping to domain [Failure].
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.cause]);
}

final class ContentNotFoundException extends AppException {
  const ContentNotFoundException(super.message, [super.cause]);
}

final class NetworkSyncException extends AppException {
  const NetworkSyncException(super.message, [super.cause]);
}
