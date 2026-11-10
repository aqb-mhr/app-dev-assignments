import 'package:flutter/material.dart';

import '../data/item_repository.dart';
import '../models/lost_item.dart';
import '../theme/app_theme.dart';

/// Form for posting a new lost or found item. Pops with the new item's
/// title once Firestore has accepted the write.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, required this.repository});

  final ItemRepository repository;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _postedBy = TextEditingController();

  ItemStatus _status = ItemStatus.found;
  String? _category;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    _postedBy.dispose();
    super.dispose();
  }

  String? _required(String? value, String what) =>
      (value == null || value.trim().isEmpty) ? 'Please enter $what' : null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await widget.repository.addItem(
        title: _title.text,
        category: _category!,
        location: _location.text,
        status: _status,
        description: _description.text,
        postedBy: _postedBy.text,
      );
      navigator.pop(_title.text.trim());
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not post item: $error')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLost = _status == ItemStatus.lost;

    return Scaffold(
      appBar: AppBar(title: const Text('Post an item')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text('What happened?', style: text.titleMedium),
                const SizedBox(height: 10),
                SegmentedButton<ItemStatus>(
                  key: const ValueKey('field-status'),
                  showSelectedIcon: false,
                  segments: [
                    for (final status in ItemStatus.postable)
                      ButtonSegment(
                        value: status,
                        icon: Icon(
                          StatusStyle.of(status, Theme.of(context).brightness)
                              .icon,
                        ),
                        label: Text(
                          status == ItemStatus.lost
                              ? 'I lost something'
                              : 'I found something',
                        ),
                      ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (selection) =>
                      setState(() => _status = selection.first),
                ),
                const SizedBox(height: 24),
                Text('Item details', style: text.titleMedium),
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('field-title'),
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Blue Water Bottle',
                    prefixIcon: Icon(Icons.label_rounded),
                  ),
                  validator: (v) => _required(v, 'a title'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const ValueKey('field-category'),
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: [
                    for (final category in ItemCategories.all)
                      DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              iconForItem(category: category),
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Text(category),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                  validator: (v) => v == null ? 'Please pick a category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('field-location'),
                  controller: _location,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText:
                        isLost ? 'Where did you lose it?' : 'Where did you find it?',
                    hintText: 'e.g. Library, 2nd Floor',
                    prefixIcon: const Icon(Icons.place_rounded),
                  ),
                  validator: (v) => _required(v, 'a location'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('field-description'),
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 400,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Colour, brand, anything that helps identify it',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => _required(v, 'a short description'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('field-posted-by'),
                  controller: _postedBy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) => _required(v, 'your name'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    key: const ValueKey('submit-item'),
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_saving ? 'Posting…' : 'Post item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
