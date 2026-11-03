import 'package:equatable/equatable.dart';

/// A single post from the feed.
///
/// This is a pure-Dart entity: it has no knowledge of Flutter, http, or JSON.
/// The data layer's `PostModel` extends it to add serialization.
class Post extends Equatable {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, userId, title, body];
}
