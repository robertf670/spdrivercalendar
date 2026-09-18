import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';

class ContactEditDialog extends StatefulWidget {
  const ContactEditDialog({
    super.key,
    this.entry,
    required this.sections,
    required this.initialSectionId,
    required this.onSave,
  });

  final ContactEntry? entry;
  final List<ContactSection> sections;
  final String initialSectionId;
  final Future<void> Function(ContactEntry draft) onSave;

  @override
  State<ContactEditDialog> createState() => _ContactEditDialogState();
}

class _ContactEditDialogState extends State<ContactEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _urlController;
  late final TextEditingController _noteController;
  late String _sectionId;
  late String _iconKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _nameController = TextEditingController(text: entry?.name ?? '');
    _phoneController = TextEditingController(text: entry?.phone ?? '');
    _emailController = TextEditingController(text: entry?.email ?? '');
    _urlController = TextEditingController(text: entry?.url ?? '');
    _noteController = TextEditingController(text: entry?.note ?? '');
    _sectionId = entry?.sectionId ?? widget.initialSectionId;
    _iconKey = entry?.iconKey ?? _iconForSection(_sectionId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _iconForSection(String sectionId) {
    for (final section in widget.sections) {
      if (section.id == sectionId) return section.iconKey;
    }
    return 'person';
  }

  Future<void> _save() async {
    final title = _titleController.text;
    final phone = _phoneController.text;
    final email = _emailController.text;
    final url = normalizeContactUrl(_urlController.text);
    final error = ContactEntry.validate(
      title: title,
      phone: phone,
      email: email,
      url: url,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _saving = true);
    try {
      final draft = ContactEntry(
        id: widget.entry?.id ?? '',
        title: title.trim(),
        name: nonEmptyString(_nameController.text),
        phone: nonEmptyString(phone),
        email: nonEmptyString(email),
        url: url,
        note: nonEmptyString(_noteController.text),
        sectionId: _sectionId,
        sortOrder: widget.entry?.sortOrder ?? 0,
        iconKey: _iconKey,
      );
      await widget.onSave(draft);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width * 0.9, 500.0);
    final sortedSections = [...widget.sections]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: media.size.width < 350 ? 16 : 24,
        vertical: 24,
      ),
      title: Text(widget.entry == null ? 'Add contact' : 'Edit contact'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: media.size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('contact_title'),
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Depot Manager',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('contact_name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  hintText: 'e.g. Tim Fitzgibbons',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('contact_phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '01 703 3462',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('contact_email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('contact_url'),
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link',
                  hintText: 'https://…',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('contact_note'),
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Shown under the title',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: sortedSections.any((s) => s.id == _sectionId)
                    ? _sectionId
                    : '',
                decoration: const InputDecoration(labelText: 'Section'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('No section'),
                  ),
                  ...sortedSections.map(
                    (section) => DropdownMenuItem(
                      value: section.id,
                      child: Text(
                        section.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _sectionId = value ?? '');
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: ContactIcons.keys.contains(_iconKey) ? _iconKey : 'person',
                decoration: const InputDecoration(labelText: 'Icon'),
                items: ContactIcons.keys
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(ContactIcons.label(key)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _iconKey = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          children: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.entry == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ],
    );
  }
}

class ContactSectionEditDialog extends StatefulWidget {
  const ContactSectionEditDialog({
    super.key,
    this.section,
    required this.onSave,
  });

  final ContactSection? section;
  final Future<void> Function(ContactSection draft) onSave;

  @override
  State<ContactSectionEditDialog> createState() =>
      _ContactSectionEditDialogState();
}

class _ContactSectionEditDialogState extends State<ContactSectionEditDialog> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late int _colorArgb;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.section?.name ?? '');
    _iconKey = widget.section?.iconKey ?? 'people';
    _colorArgb =
        widget.section?.colorArgb ?? ContactColors.palette['primary']!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section name required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        ContactSection(
          id: widget.section?.id ?? '',
          name: name,
          sortOrder: widget.section?.sortOrder ?? 0,
          iconKey: _iconKey,
          colorArgb: _colorArgb,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width * 0.9, 500.0);
    final colorValue = ContactColors.palette.values.contains(_colorArgb)
        ? _colorArgb
        : ContactColors.palette['primary']!;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: media.size.width < 350 ? 16 : 24,
        vertical: 24,
      ),
      title: Text(widget.section == null ? 'Add section' : 'Edit section'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: media.size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('contact_section_name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Controllers',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: ContactIcons.keys.contains(_iconKey) ? _iconKey : 'people',
                decoration: const InputDecoration(labelText: 'Icon'),
                items: ContactIcons.keys
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(ContactIcons.label(key)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _iconKey = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: colorValue,
                decoration: const InputDecoration(labelText: 'Colour'),
                items: ContactColors.palette.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.value,
                        child: Text(entry.key),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _colorArgb = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          children: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.section == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ],
    );
  }
}
