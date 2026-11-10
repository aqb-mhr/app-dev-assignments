import 'package:flutter/material.dart';

import 'data/item_repository.dart';
import 'screens/item_list_screen.dart';
import 'theme/app_theme.dart';

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key, required this.repository});

  final ItemRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: ItemListScreen(repository: repository),
    );
  }
}
