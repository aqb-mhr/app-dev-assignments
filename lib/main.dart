import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:posts_clean_bloc/core/theme/app_theme.dart';
import 'package:posts_clean_bloc/features/posts/data/datasources/post_remote_data_source.dart';
import 'package:posts_clean_bloc/features/posts/data/repositories/post_repository_impl.dart';
import 'package:posts_clean_bloc/features/posts/domain/repositories/post_repository.dart';
import 'package:posts_clean_bloc/features/posts/domain/usecases/get_posts.dart';
import 'package:posts_clean_bloc/features/posts/presentation/bloc/post_bloc.dart';
import 'package:posts_clean_bloc/features/posts/presentation/pages/posts_list_page.dart';

void main() {
  // Composition root: the one place the layers are wired together. The code
  // below never lets data concerns reach into presentation — it only assembles
  // concrete implementations behind their domain abstractions.
  final http.Client client = http.Client();

  final PostRemoteDataSource remoteDataSource =
      PostRemoteDataSourceImpl(client: client);

  final PostRepository repository =
      PostRepositoryImpl(remoteDataSource: remoteDataSource);

  final GetPosts getPosts = GetPosts(repository);

  runApp(PostsApp(getPosts: getPosts));
}

class PostsApp extends StatelessWidget {
  const PostsApp({super.key, required this.getPosts});

  final GetPosts getPosts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts Clean BLoC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: BlocProvider(
        create: (_) => PostBloc(getPosts: getPosts)..add(const FetchPosts()),
        child: const PostsListPage(),
      ),
    );
  }
}
