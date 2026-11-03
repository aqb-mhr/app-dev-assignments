/// Raw exceptions thrown inside the data layer. These never leave the data
/// layer — [PostRepositoryImpl] catches them and maps them to a [Failure].
library;

/// Thrown by the remote data source when the API returns a non-200 status
/// or the response body cannot be parsed.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
}

/// Thrown by the remote data source when the request cannot reach the server
/// (socket error, timeout, DNS failure).
class NetworkException implements Exception {
  const NetworkException([this.message = 'Network error']);
  final String message;
}
