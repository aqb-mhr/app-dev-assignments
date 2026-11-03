part of 'post_bloc.dart';

sealed class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch (or re-fetch) the list of posts. Used for the first load, pull-to-
/// refresh, and retry — [isRefresh] lets the UI keep showing the old list
/// while a pull-to-refresh runs, instead of flashing the full-screen loader.
class FetchPosts extends PostEvent {
  const FetchPosts({this.isRefresh = false});

  final bool isRefresh;

  @override
  List<Object?> get props => [isRefresh];
}
