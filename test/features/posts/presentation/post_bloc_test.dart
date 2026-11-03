import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:posts_clean_bloc/core/error/failures.dart';
import 'package:posts_clean_bloc/core/error/result.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';
import 'package:posts_clean_bloc/features/posts/domain/usecases/get_posts.dart';
import 'package:posts_clean_bloc/features/posts/presentation/bloc/post_bloc.dart';

class _MockGetPosts extends Mock implements GetPosts {}

void main() {
  late _MockGetPosts getPosts;

  setUp(() {
    getPosts = _MockGetPosts();
  });

  const posts = [
    Post(id: 1, userId: 1, title: 'a', body: 'b'),
  ];

  blocTest<PostBloc, PostState>(
    'emits [PostLoading, PostLoaded] when the fetch succeeds',
    build: () {
      when(() => getPosts()).thenAnswer((_) async => const Success(posts));
      return PostBloc(getPosts: getPosts);
    },
    act: (bloc) => bloc.add(const FetchPosts()),
    expect: () => const [
      PostLoading(),
      PostLoaded(posts),
    ],
  );

  blocTest<PostBloc, PostState>(
    'emits [PostLoading, PostError] when the fetch fails',
    build: () {
      when(() => getPosts())
          .thenAnswer((_) async => const ResultFailure(NetworkFailure()));
      return PostBloc(getPosts: getPosts);
    },
    act: (bloc) => bloc.add(const FetchPosts()),
    expect: () => [
      const PostLoading(),
      isA<PostError>(),
    ],
  );
}
