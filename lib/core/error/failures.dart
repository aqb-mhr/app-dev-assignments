import 'package:equatable/equatable.dart';

/// Domain-level error. The UI only ever sees a [Failure], never a raw
/// exception from the network or JSON parsing.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The request reached the server but it responded with an error status,
/// or the request could not be made at all (no connection, timeout).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

/// The device has no usable internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}
