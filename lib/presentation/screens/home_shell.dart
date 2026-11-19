import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/booking_providers.dart';
import 'my_bookings_screen.dart';
import 'rooms_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // All SnackBars for booking actions are triggered HERE, from the widget,
    // by listening to the controller - the provider never sees a BuildContext.
    ref.listen<AsyncValue<String?>>(bookingControllerProvider, (prev, next) {
      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      switch (next) {
        case AsyncError(:final error):
          messenger.showSnackBar(SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        case AsyncData(:final value) when value != null && prev is AsyncLoading:
          messenger.showSnackBar(SnackBar(content: Text(value)));
        default:
          break;
      }
    });

    final user = ref.watch(currentUserProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    final busy = ref.watch(bookingControllerProvider).isLoading;

    final pages = <Widget>[
      const RoomsScreen(),
      const MyBookingsScreen(),
      if (isAdmin) const RoomsScreen(adminMode: true),
    ];
    final index = _index.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (index) {
          0 => 'IBA RoomBook',
          1 => 'My bookings',
          _ => 'Admin · all bookings',
        }),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  isAdmin ? '${user.name} (admin)' : user.name,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined), label: 'Rooms'),
          const NavigationDestination(
              icon: Icon(Icons.event_note_outlined), label: 'My bookings'),
          if (isAdmin)
            const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: 'Admin'),
        ],
      ),
    );
  }
}
