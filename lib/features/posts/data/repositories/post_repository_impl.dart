import 'package:posts_clean_bloc/core/error/exceptions.dart';
import 'package:posts_clean_bloc/core/error/failures.dart';
import 'package:posts_clean_bloc/core/error/result.dart';
import 'package:posts_clean_bloc/features/posts/data/datasources/post_remote_data_source.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';
import 'package:posts_clean_bloc/features/posts/domain/repositories/post_repository.dart';

/// Implements the domain contract. Its one job beyond delegating is to turn
/// raw data-layer exceptions into clean domain [Failure]s, so no exception
/// ever leaks into the presentation layer.
class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl({required this.remoteDataSource});

  final PostRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Post>>> getPosts() async {
    try {
      final posts = await remoteDataSource.getPosts();
      return Success(posts);
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } catch (_) {
      return const ResultFailure(ServerFailure());
    }
  }
}
