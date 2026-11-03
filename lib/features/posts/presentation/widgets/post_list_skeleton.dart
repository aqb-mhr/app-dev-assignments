import 'package:flutter/material.dart';

/// A lightweight placeholder list shown during the first load. It mirrors the
/// shape of the real list (avatar + two text lines) so the transition to real
/// content is calm rather than a jarring spinner-to-list jump.
class PostListSkeleton extends StatefulWidget {
  const PostListSkeleton({super.key});

  @override
  State<PostListSkeleton> createState() => _PostListSkeletonState();
}

class _PostListSkeletonState extends State<PostListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) => FadeTransition(
        opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
        child: const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(double.infinity, 14),
                  const SizedBox(height: 8),
                  bar(220, 12),
                  const SizedBox(height: 10),
                  bar(double.infinity, 10),
                  const SizedBox(height: 6),
                  bar(160, 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
