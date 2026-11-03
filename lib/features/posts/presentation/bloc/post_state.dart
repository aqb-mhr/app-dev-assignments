part of 'post_bloc.dart';

sealed class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet.
class PostInitial extends PostState {
  const PostInitial();
}

/// First fetch in progress — the UI shows a full-screen loading indicator.
class PostLoading extends PostState {
  const PostLoading();
}

/// Posts fetched successfully.
///
/// [isRefreshing] is true while a pull-to-refresh is running on top of an
/// already-loaded list, so the UI can show the refresh spinner without
/// discarding the posts it is already showing.
class PostLoaded extends PostState {
  const PostLoaded(this.posts, {this.isRefreshing = false});

  final List<Post> posts;
  final bool isRefreshing;

  PostLoaded copyWith({List<Post>? posts, bool? isRefreshing}) {
    return PostLoaded(
      posts ?? this.posts,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [posts, isRefreshing];
}

/// The fetch failed — the UI shows the message and a retry button.
class PostError extends PostState {
  const PostError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
