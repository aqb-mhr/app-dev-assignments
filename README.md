# Posts Clean BLoC

A small Flutter app that fetches live posts from a public REST API and displays them, structured with **Clean Architecture** (domain / data / presentation) and **flutter_bloc** for state management.

Assignment 2 — Application Development for Mobile Devices (CSE-450), IBA Karachi.

## What it does

- Lists all posts from `https://jsonplaceholder.typicode.com/posts`
- Pull-to-refresh re-fetches the list
- Clear loading state on first fetch
- Clear error state with a retry button when the request fails
- Tapping a post opens a detail screen with its full title and body

## Architecture

```
lib/
├── core/
│   ├── error/            # Failure + Exception types (domain-level errors)
│   └── network/          # Thin wrapper over the http client
└── features/posts/
    ├── domain/           # Pure Dart — no Flutter, no http, no json
    │   ├── entities/        Post
    │   ├── repositories/    PostRepository (abstract)
    │   └── usecases/        GetPosts
    ├── data/             # Talks to the outside world
    │   ├── models/          PostModel (extends Post, fromJson)
    │   ├── datasources/     PostRemoteDataSource (http)
    │   └── repositories/    PostRepositoryImpl (maps failures)
    └── presentation/     # Flutter + BLoC
        ├── bloc/            PostEvent / PostState / PostBloc
        ├── pages/           PostsListPage, PostDetailPage
        └── widgets/         Reusable UI pieces
```

### Dependency rule

Dependencies point inward. `domain` knows nothing about `data` or `presentation`.
`data` implements `domain` contracts. `presentation` depends on `domain` use cases
and never touches `http` or `json` directly.

```
presentation  ──▶  domain  ◀──  data
```

## Run

```bash
flutter pub get
flutter run
```

Requires the Flutter SDK (Dart ^3.5.0). Tested target: Android / iOS / web.

## Test the error state

Turn off your device/emulator internet connection and pull-to-refresh (or tap
retry). The app surfaces a clean domain-level failure, not a raw exception.

## Tests

```bash
flutter test
```

Unit tests cover the use case, the repository's error mapping, and the BLoC's
state transitions.
