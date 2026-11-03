import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posts_clean_bloc/core/error/result.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';
import 'package:posts_clean_bloc/features/posts/domain/usecases/get_posts.dart';

part 'post_event.dart';
part 'post_state.dart';

/// Wires [FetchPosts] events to the [GetPosts] use case and emits the
/// initial / loading / loaded / error states the UI renders.
class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc({required GetPosts getPosts})
      : _getPosts = getPosts,
        super(const PostInitial()) {
    on<FetchPosts>(_onFetchPosts);
  }

  final GetPosts _getPosts;

  Future<void> _onFetchPosts(
    FetchPosts event,
    Emitter<PostState> emit,
  ) async {
    final current = state;

    // On pull-to-refresh over an existing list, keep the list visible and
    // just flag it as refreshing. Otherwise show the full-screen loader.
    if (event.isRefresh && current is PostLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const PostLoading());
    }

    final result = await _getPosts();

    switch (result) {
      case Success(value: final posts):
        emit(PostLoaded(posts));
      case ResultFailure(failure: final failure):
        // If a refresh fails, prefer keeping the stale list over a blank
        // error screen; otherwise surface the error state.
        if (event.isRefresh && current is PostLoaded) {
          emit(current.copyWith(isRefreshing: false));
        } else {
          emit(PostError(failure.message));
        }
    }
  }
}
