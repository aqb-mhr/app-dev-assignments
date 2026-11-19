import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/room_providers.dart';
import '../widgets/date_selector.dart';
import '../widgets/room_card.dart';
import '../widgets/slot_strip.dart';

/// Live room grid. Used for students (adminMode = false) and for the admin
/// dashboard tab (adminMode = true: shows who booked + force-cancel).
class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key, this.adminMode = false});

  final bool adminMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DateSelector(),
        const SlotLegend(),
        const SizedBox(height: 6),
        Expanded(
          child: roomsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText('Could not load rooms:\n$e',
                    textAlign: TextAlign.center),
              ),
            ),
            data: (rooms) => rooms.isEmpty
                ? const Center(
                    child: Text('No rooms yet - seed the rooms collection.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: rooms.length,
                    itemBuilder: (_, i) =>
                        RoomCard(room: rooms[i], adminMode: adminMode),
                  ),
          ),
        ),
      ],
    );
  }
}
