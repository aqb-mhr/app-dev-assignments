import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:posts_clean_bloc/core/error/exceptions.dart';
import 'package:posts_clean_bloc/core/error/failures.dart';
import 'package:posts_clean_bloc/core/error/result.dart';
import 'package:posts_clean_bloc/features/posts/data/datasources/post_remote_data_source.dart';
import 'package:posts_clean_bloc/features/posts/data/models/post_model.dart';
import 'package:posts_clean_bloc/features/posts/data/repositories/post_repository_impl.dart';

class _MockRemoteDataSource extends Mock implements PostRemoteDataSource {}

void main() {
  late PostRepositoryImpl repository;
  late _MockRemoteDataSource dataSource;

  setUp(() {
    dataSource = _MockRemoteDataSource();
    repository = PostRepositoryImpl(remoteDataSource: dataSource);
  });

  const models = [
    PostModel(id: 1, userId: 1, title: 'a', body: 'b'),
  ];

  test('returns Success with posts when the data source succeeds', () async {
    when(() => dataSource.getPosts()).thenAnswer((_) async => models);

    final result = await repository.getPosts();

    expect(result, isA<Success>());
    expect((result as Success).value, models);
  });

  test('maps NetworkException to NetworkFailure', () async {
    when(() => dataSource.getPosts()).thenThrow(const NetworkException());

    final result = await repository.getPosts();

    expect(result, isA<ResultFailure>());
    expect((result as ResultFailure).failure, isA<NetworkFailure>());
  });

  test('maps ServerException to ServerFailure', () async {
    when(() => dataSource.getPosts()).thenThrow(const ServerException());

    final result = await repository.getPosts();

    expect(result, isA<ResultFailure>());
    expect((result as ResultFailure).failure, isA<ServerFailure>());
  });

  test('maps any unexpected error to ServerFailure', () async {
    when(() => dataSource.getPosts()).thenThrow(Exception('boom'));

    final result = await repository.getPosts();

    expect(result, isA<ResultFailure>());
    expect((result as ResultFailure).failure, isA<ServerFailure>());
  });
}
