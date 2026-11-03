import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';

/// Data-layer representation of a [Post] that knows how to deserialize itself
/// from the API's JSON. It extends the domain entity so the rest of the app
/// can treat it as a plain [Post].
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
  });

  /// Builds a model from one JSON object in the API response.
  ///
  /// Throws a [FormatException] / [TypeError] on malformed data, which the
  /// remote data source catches and converts to a `ServerException`.
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };
}
