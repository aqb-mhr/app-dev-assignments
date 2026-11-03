import 'package:posts_clean_bloc/core/error/result.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';
import 'package:posts_clean_bloc/features/posts/domain/repositories/post_repository.dart';

/// Use case: fetch all posts.
///
/// A use case holds one unit of business logic and delegates to the
/// repository contract. The BLoC calls this instead of the repository
/// directly, which keeps the presentation layer one more step removed from
/// data concerns.
class GetPosts {
  const GetPosts(this._repository);

  final PostRepository _repository;

  /// Callable so it reads like `getPosts()` at the call site.
  Future<Result<List<Post>>> call() => _repository.getPosts();
}
