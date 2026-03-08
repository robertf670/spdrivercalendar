import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/toilet_codes_service.dart';

class ToiletCodesManagementScreen extends StatelessWidget {
  const ToiletCodesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Toilet Codes'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Changes sync to all app users',
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ToiletCodeEntry>>(
              stream: ToiletCodesService.getEntriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wc,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No toilet codes yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              await ToiletCodesService.seedDefaults();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Default codes loaded'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Load defaults'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(entry.locationName),
                        subtitle: Text(
                          entry.codes.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join(' • '),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(context, entry),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, entry),
                            ),
                          ],
                        ),
                        onTap: () => _showEditDialog(context, entry),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addToiletCode',
        onPressed: () => _showEditDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ToiletCodeEntry? existing) {
    showDialog(
      context: context,
      builder: (_) => _ToiletCodeEditDialog(
        entry: existing,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ToiletCodeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
            'Remove ${entry.locationName}? This will sync to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ToiletCodesService.deleteEntry(entry.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ToiletCodeEditDialog extends StatefulWidget {
  final ToiletCodeEntry? entry;

  const _ToiletCodeEditDialog({
    this.entry,
  });

  @override
  State<_ToiletCodeEditDialog> createState() => _ToiletCodeEditDialogState();
}

class _ToiletCodeEditDialogState extends State<_ToiletCodeEditDialog> {
  late TextEditingController _locationController;
  late TextEditingController _instructionController;
  final List<TextEditingController> _labelControllers = [];
  final List<TextEditingController> _valueControllers = [];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.entry?.locationName ?? '');
    _instructionController =
        TextEditingController(text: widget.entry?.instruction ?? '');
    if (widget.entry != null && widget.entry!.codes.isNotEmpty) {
      for (final e in widget.entry!.codes.entries) {
        _labelControllers.add(TextEditingController(text: e.key == 'Code' ? '' : e.key));
        _valueControllers.add(TextEditingController(text: e.value));
      }
    } else {
      _labelControllers.add(TextEditingController(text: ''));
      _valueControllers.add(TextEditingController(text: ''));
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _instructionController.dispose();
    for (final c in _labelControllers) c.dispose();
    for (final c in _valueControllers) c.dispose();
    super.dispose();
  }

  void _addCodeRow() {
    setState(() {
      _labelControllers.add(TextEditingController(text: ''));
      _valueControllers.add(TextEditingController(text: ''));
    });
  }

  void _removeCodeRow(int index) {
    if (_labelControllers.length <= 1) return;
    setState(() {
      _labelControllers[index].dispose();
      _valueControllers[index].dispose();
      _labelControllers.removeAt(index);
      _valueControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entry == null ? 'Add location' : 'Edit location'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location name',
                hintText: 'e.g. Adamstown',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Codes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(_labelControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _labelControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Label (e.g. Gents, 1st door)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _valueControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Code',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _labelControllers.length > 1
                          ? () => _removeCodeRow(index)
                          : null,
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addCodeRow,
              icon: const Icon(Icons.add),
              label: const Text('Add another code'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionController,
              decoration: const InputDecoration(
                labelText: 'Instruction (optional)',
                hintText: 'e.g. Turn handle to the right',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final location = _locationController.text.trim();
            if (location.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location name required')),
              );
              return;
            }
            final codes = <String, String>{};
            for (var i = 0; i < _labelControllers.length; i++) {
              final value = _valueControllers[i].text.trim();
              if (value.isEmpty) continue;
              final label = _labelControllers[i].text.trim();
              codes[label.isEmpty ? 'Code' : label] = value;
            }
            if (codes.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('At least one code required')),
              );
              return;
            }
            final instruction = _instructionController.text.trim();
            final instructionOrNull =
                instruction.isEmpty ? null : instruction;

            try {
              if (widget.entry != null) {
                await ToiletCodesService.updateEntry(
                  widget.entry!.copyWith(
                    locationName: location,
                    codes: codes,
                    instruction: instructionOrNull,
                    clearInstruction: instructionOrNull == null,
                  ),
                );
              } else {
                await ToiletCodesService.addEntry(
                  ToiletCodeEntry(
                    id: '',
                    locationName: location,
                    codes: codes,
                    instruction: instructionOrNull,
                  ),
                );
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        widget.entry == null ? 'Added' : 'Updated'),
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
          child: Text(widget.entry == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
