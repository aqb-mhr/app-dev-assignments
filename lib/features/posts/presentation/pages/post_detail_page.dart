import 'package:flutter/material.dart';
import 'package:posts_clean_bloc/features/posts/domain/entities/post.dart';

/// Shows the full title and body of a single post. Receives the [Post] via the
/// constructor — no extra fetch needed since the list already has the data.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  static Route<void> route(Post post) {
    return MaterialPageRoute(
      builder: (_) => PostDetailPage(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(
                  icon: Icons.tag_rounded,
                  label: 'Post ${post.id}',
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.person_outline_rounded,
                  label: 'User ${post.userId}',
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _titleCase(post.title),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              post.body,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: colors.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.onSecondaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.onSecondaryContainer,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
