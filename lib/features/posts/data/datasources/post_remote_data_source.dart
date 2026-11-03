import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:posts_clean_bloc/core/error/exceptions.dart';
import 'package:posts_clean_bloc/core/network/api_constants.dart';
import 'package:posts_clean_bloc/features/posts/data/models/post_model.dart';

/// Talks directly to the REST API. This is the only place `http` and
/// `dart:convert` are used. It throws raw data-layer exceptions; mapping to
/// domain failures happens one layer up in the repository implementation.
abstract class PostRemoteDataSource {
  Future<List<PostModel>> getPosts();
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  PostRemoteDataSourceImpl({required this.client});

  final http.Client client;

  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<List<PostModel>> getPosts() async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.posts),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as List<dynamic>;
        return decoded
            .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw ServerException('Request failed (${response.statusCode}).');
    } on SocketException {
      // No route to host / DNS failure / offline.
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('The request timed out.');
    } on FormatException {
      // Body was not valid JSON or had an unexpected shape.
      throw const ServerException('Could not parse the server response.');
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }
}
