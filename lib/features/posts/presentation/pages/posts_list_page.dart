import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';
import 'package:posts_clean_bloc/features/posts/presentation/bloc/post_bloc.dart';
import 'package:posts_clean_bloc/features/posts/presentation/pages/post_detail_page.dart';
import 'package:posts_clean_bloc/features/posts/presentation/widgets/post_card.dart';
import 'package:posts_clean_bloc/features/posts/presentation/widgets/post_error_view.dart';
import 'package:posts_clean_bloc/features/posts/presentation/widgets/post_list_skeleton.dart';

/// The main screen. The [PostBloc] is provided above this widget (in
/// `main.dart`, wired with its use case), so here we just read it, trigger the
/// first fetch, and render the right UI for each state via [BlocBuilder].
class PostsListPage extends StatelessWidget {
  const PostsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        centerTitle: false,
      ),
      body: BlocBuilder<PostBloc, PostState>(
        builder: (context, state) {
          return switch (state) {
            PostInitial() || PostLoading() => const PostListSkeleton(),
            PostError(message: final message) => PostErrorView(
                message: message,
                onRetry: () =>
                    context.read<PostBloc>().add(const FetchPosts()),
              ),
            PostLoaded(posts: final posts) => _PostsList(posts: posts),
          };
        },
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.posts});

  final List<Post> posts;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<PostBloc>();
    bloc.add(const FetchPosts(isRefresh: true));
    // Keep the pull-to-refresh spinner up until the refresh actually settles.
    await bloc.stream.firstWhere(
      (s) => s is! PostLoaded || !s.isRefreshing,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('No posts yet.'));
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostCard(
            post: post,
            onTap: () =>
                Navigator.of(context).push(PostDetailPage.route(post)),
          );
        },
      ),
    );
  }
}
