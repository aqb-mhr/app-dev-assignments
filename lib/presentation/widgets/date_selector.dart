import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/date_utils.dart';
import '../providers/core_providers.dart';
import '../providers/room_providers.dart';

/// Today + next 6 days as choice chips.
class DateSelector extends ConsumerWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowTickerProvider).value ?? ref.read(clockProvider)();
    final selected = ref.watch(selectedDateProvider);
    final days = bookableDates(now);
    final today = dateOnly(now);

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final label = day == today
              ? 'Today'
              : DateFormat('EEE d MMM').format(day);
          return ChoiceChip(
            label: Text(label),
            selected: day == selected,
            onSelected: (_) =>
                ref.read(selectedDateProvider.notifier).select(day),
          );
        },
      ),
    );
  }
}
