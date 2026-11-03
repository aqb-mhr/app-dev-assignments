import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:posts_clean_bloc/core/error/failures.dart';
import 'package:posts_clean_bloc/core/error/result.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';
import 'package:posts_clean_bloc/features/posts/domain/repositories/post_repository.dart';
import 'package:posts_clean_bloc/features/posts/domain/usecases/get_posts.dart';

class _MockPostRepository extends Mock implements PostRepository {}

void main() {
  late GetPosts usecase;
  late _MockPostRepository repository;

  setUp(() {
    repository = _MockPostRepository();
    usecase = GetPosts(repository);
  });

  const posts = [
    Post(id: 1, userId: 1, title: 'a', body: 'b'),
  ];

  test('returns posts from the repository on success', () async {
    when(() => repository.getPosts())
        .thenAnswer((_) async => const Success(posts));

    final result = await usecase();

    expect(result, isA<Success<List<Post>>>());
    expect((result as Success).value, posts);
    verify(() => repository.getPosts()).called(1);
  });

  test('passes a failure straight through', () async {
    when(() => repository.getPosts())
        .thenAnswer((_) async => const ResultFailure(NetworkFailure()));

    final result = await usecase();

    expect(result, isA<ResultFailure<List<Post>>>());
  });
}
