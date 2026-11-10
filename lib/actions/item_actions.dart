import 'package:flutter/material.dart';

import '../data/item_repository.dart';
import '../models/lost_item.dart';

/// Asks for confirmation, then runs the claim transaction and reports the
/// outcome (including "someone else claimed it first") in a snackbar.
/// Returns null if the user cancelled or the write failed.
Future<ClaimOutcome?> confirmAndClaim(
  BuildContext context,
  ItemRepository repository,
  LostItem item, {
  VoidCallback? onConfirmed,
}) async {  
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.handshake_rounded),
      title: const Text('Mark as claimed?'),
      content: Text(
        'Confirm that "${item.title}" has been returned to its owner. '
        'This can\'t be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-claim'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Mark as claimed'),
        ),
      ],
    ),
  );
  if (confirmed != true) return null;
  onConfirmed?.call();
  try {
    final outcome = await repository.markAsClaimed(item.id);
    final message = switch (outcome) {
      ClaimOutcome.claimed => '"${item.title}" marked as claimed',
      ClaimOutcome.alreadyClaimed =>
        'Someone else already marked this as claimed',
      ClaimOutcome.notFound => 'This item no longer exists',
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return outcome;
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not update item: $error')),
    );
    return null;
  }
}

/// Asks for confirmation, deletes the item and offers an "Undo" that writes
/// it back under the same id. [beforeDelete] runs right after the user
/// confirms (the detail screen uses it to close itself first).
/// Returns true if the item was deleted.
Future<bool> confirmAndDelete(
  BuildContext context,
  ItemRepository repository,
  LostItem item, {
  VoidCallback? beforeDelete,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
      title: const Text('Delete this post?'),
      content: Text('"${item.title}" will be removed for everyone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-delete'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  beforeDelete?.call();
  try {
    await repository.deleteItem(item.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${item.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            repository.restoreItem(item).catchError((Object error) {
              messenger.showSnackBar(
                SnackBar(content: Text('Could not restore item: $error')),
              );
            });
          },
        ),
      ),
    );
    return true;
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not delete item: $error')),
    );
    return false;
  }
}
