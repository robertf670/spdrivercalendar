import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';
import 'package:spdrivercalendar/features/contacts/dialogs/contact_admin_dialogs.dart';
import 'package:spdrivercalendar/services/contacts_service.dart';

class ContactsManagementScreen extends StatefulWidget {
  const ContactsManagementScreen({super.key});

  @override
  State<ContactsManagementScreen> createState() =>
      _ContactsManagementScreenState();
}

class _ContactsManagementScreenState extends State<ContactsManagementScreen> {
  late final Future<void> _seedFuture;

  @override
  void initState() {
    super.initState();
    _seedFuture = ContactsService.seedDefaults();
  }

  Future<void> _editContact(
    BuildContext context, {
    required ContactsCatalog catalog,
    ContactEntry? existing,
    String? sectionId,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => ContactEditDialog(
        entry: existing,
        sections: catalog.sections,
        initialSectionId: existing?.sectionId ?? sectionId ?? '',
        onSave: (draft) async {
          if (existing == null) {
            await ContactsService.addEntry(
              draft.copyWith(
                sortOrder: catalog.nextEntrySortOrder(draft.sectionId),
              ),
            );
          } else {
            await ContactsService.updateEntry(
              draft.copyWith(sortOrder: existing.sortOrder),
            );
          }
        },
      ),
    );
  }

  Future<void> _editSection(
    BuildContext context, {
    required ContactsCatalog catalog,
    ContactSection? existing,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => ContactSectionEditDialog(
        section: existing,
        onSave: (draft) async {
          if (existing == null) {
            await ContactsService.addSection(
              draft.copyWith(sortOrder: catalog.nextSectionSortOrder()),
            );
          } else {
            await ContactsService.updateSection(
              draft.copyWith(sortOrder: existing.sortOrder),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteContact(
    BuildContext context,
    ContactEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Remove ${entry.title}? This will sync to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ContactsService.deleteEntry(entry.id);
    }
  }

  Future<void> _confirmDeleteSection(
    BuildContext context,
    ContactSection section,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete section'),
        content: Text(
          'Remove ${section.name}? Contacts in it stay in the list with no section. This will sync to all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ContactsService.deleteSection(section.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Contacts'),
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
            child: FutureBuilder<void>(
              future: _seedFuture,
              builder: (context, seedSnap) {
                return StreamBuilder<ContactsCatalog>(
                  stream: ContactsService.watchCatalog(
                    fallbackToDefaults: false,
                  ),
                  builder: (context, snapshot) {
                    if (seedSnap.connectionState != ConnectionState.done ||
                        (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final catalog = snapshot.data ?? const ContactsCatalog();
                    if (catalog.isEmpty) {
                      return _EmptyAdminState(
                        onLoadDefaults: () async {
                          await ContactsService.seedDefaults();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Default contacts loaded'),
                              ),
                            );
                          }
                        },
                      );
                    }

                    return _AdminContactList(
                      catalog: catalog,
                      onAddContact: (sectionId) => _editContact(
                        context,
                        catalog: catalog,
                        sectionId: sectionId,
                      ),
                      onEditContact: (entry) => _editContact(
                        context,
                        catalog: catalog,
                        existing: entry,
                      ),
                      onDeleteContact: (entry) =>
                          _confirmDeleteContact(context, entry),
                      onAddSection: () =>
                          _editSection(context, catalog: catalog),
                      onEditSection: (section) => _editSection(
                        context,
                        catalog: catalog,
                        existing: section,
                      ),
                      onDeleteSection: (section) =>
                          _confirmDeleteSection(context, section),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState({required this.onLoadDefaults});

  final VoidCallback onLoadDefaults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No contacts yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onLoadDefaults,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Load defaults'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminContactList extends StatelessWidget {
  const _AdminContactList({
    required this.catalog,
    required this.onAddContact,
    required this.onEditContact,
    required this.onDeleteContact,
    required this.onAddSection,
    required this.onEditSection,
    required this.onDeleteSection,
  });

  final ContactsCatalog catalog;
  final ValueChanged<String> onAddContact;
  final ValueChanged<ContactEntry> onEditContact;
  final ValueChanged<ContactEntry> onDeleteContact;
  final VoidCallback onAddSection;
  final ValueChanged<ContactSection> onEditSection;
  final ValueChanged<ContactSection> onDeleteSection;

  @override
  Widget build(BuildContext context) {
    final groups = catalog.grouped();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAddSection,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Add section'),
              ),
              FilledButton.icon(
                onPressed: () => onAddContact(''),
                icon: const Icon(Icons.add),
                label: const Text('Add contact'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final group in groups) ...[
          if (group.section != null)
            _SectionHeader(
              section: group.section!,
              onEdit: () => onEditSection(group.section!),
              onDelete: () => onDeleteSection(group.section!),
              onAdd: () => onAddContact(group.section!.id),
            )
          else if (group.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'No section',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          if (group.entries.isEmpty && group.section != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No contacts in this section',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          for (final entry in group.entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 16, right: 4),
                leading: Icon(
                  ContactIcons.data(entry.iconKey),
                  color: catalog.colorFor(entry, group.section),
                ),
                title: Text(entry.title),
                subtitle: Text(
                  _adminSubtitle(entry),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      onPressed: () => onEditContact(entry),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => onDeleteContact(entry),
                    ),
                  ],
                ),
                onTap: () => onEditContact(entry),
              ),
            ),
        ],
      ],
    );
  }

  String _adminSubtitle(ContactEntry entry) {
    final parts = <String>[
      if (entry.name != null) entry.name!,
      if (entry.hasPhone) entry.phone!,
      if (entry.hasEmail) entry.email!,
      if (entry.hasUrl) 'link',
    ];
    return parts.join(' • ');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.section,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final ContactSection section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 6 : 8),
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ContactIcons.data(section.iconKey),
              color: section.color,
              size: isSmall ? 18 : 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.name,
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: section.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Section options',
            onSelected: (value) {
              switch (value) {
                case 'add':
                  onAdd();
                case 'edit':
                  onEdit();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'add', child: Text('Add contact')),
              PopupMenuItem(value: 'edit', child: Text('Edit section')),
              PopupMenuItem(value: 'delete', child: Text('Delete section')),
            ],
          ),
        ],
      ),
    );
  }
}
