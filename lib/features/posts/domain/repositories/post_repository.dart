import 'package:posts_clean_bloc/core/error/result.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';

/// The contract the domain layer depends on. The data layer provides the
/// implementation. The domain never knows *how* posts are fetched.
abstract class PostRepository {
  /// Returns the list of posts, or a [Failure] wrapped in a [Result].
  Future<Result<List<Post>>> getPosts();
}
