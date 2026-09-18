import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

String? nonEmptyString(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String digitsForTel(String phone) =>
    phone.replaceAll(RegExp(r'[^\d+]'), '');

const Object _unset = Object();

String? normalizeContactUrl(String? url) {
  final trimmed = url?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

class ContactIcons {
  static const keys = <String>[
    'business',
    'paid',
    'people',
    'badge',
    'admin_panel_settings',
    'headset_mic',
    'support_agent',
    'inventory',
    'description',
    'medical_services',
    'phone',
    'email',
    'link',
    'person',
  ];

  static const labels = <String, String>{
    'business': 'Business',
    'paid': 'Pay',
    'people': 'People',
    'badge': 'Badge',
    'admin_panel_settings': 'Admin',
    'headset_mic': 'Headset',
    'support_agent': 'Support',
    'inventory': 'Inventory',
    'description': 'Document',
    'medical_services': 'Medical',
    'phone': 'Phone',
    'email': 'Email',
    'link': 'Link',
    'person': 'Person',
  };

  static IconData data(String? key) {
    switch (key) {
      case 'business':
        return Icons.business;
      case 'paid':
        return Icons.paid;
      case 'people':
        return Icons.people;
      case 'badge':
        return Icons.badge;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'headset_mic':
        return Icons.headset_mic;
      case 'support_agent':
        return Icons.support_agent;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'description':
        return Icons.description;
      case 'medical_services':
        return Icons.medical_services;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'link':
        return Icons.open_in_new;
      default:
        return Icons.person;
    }
  }

  static String label(String key) => labels[key] ?? key;
}

class ContactColors {
  static const palette = <String, int>{
    'primary': 0xFF1E88E5,
    'secondary': 0xFF26A69A,
    'orange': 0xFFFF9800,
    'indigo': 0xFF3F51B5,
    'teal': 0xFF009688,
    'purple': 0xFF9C27B0,
    'brown': 0xFF795548,
    'red': 0xFFE53935,
    'green': 0xFF43A047,
  };

  static Color color(int argb) => Color(argb);

  static String nameFor(int argb) {
    for (final entry in palette.entries) {
      if (entry.value == argb) return entry.key;
    }
    return 'custom';
  }
}

class ContactSection {
  const ContactSection({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.iconKey,
    required this.colorArgb,
  });

  final String id;
  final String name;
  final int sortOrder;
  final String iconKey;
  final int colorArgb;

  Color get color => Color(colorArgb);

  Map<String, dynamic> toFirestore() => {
        'name': name.trim(),
        'sortOrder': sortOrder,
        'iconKey': iconKey,
        'colorArgb': colorArgb,
      };

  factory ContactSection.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) =>
      ContactSection(
        id: id,
        name: data['name'] as String? ?? '',
        sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
        iconKey: data['iconKey'] as String? ?? 'people',
        colorArgb: (data['colorArgb'] as num?)?.toInt() ??
            ContactColors.palette['primary']!,
      );

  ContactSection copyWith({
    String? id,
    String? name,
    int? sortOrder,
    String? iconKey,
    int? colorArgb,
  }) =>
      ContactSection(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        iconKey: iconKey ?? this.iconKey,
        colorArgb: colorArgb ?? this.colorArgb,
      );
}

class ContactEntry {
  const ContactEntry({
    required this.id,
    required this.title,
    required this.sectionId,
    required this.sortOrder,
    required this.iconKey,
    this.name,
    this.phone,
    this.email,
    this.url,
    this.note,
  });

  final String id;
  final String title;
  final String? name;
  final String? phone;
  final String? email;
  final String? url;
  final String? note;
  final String sectionId;
  final int sortOrder;
  final String iconKey;

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasEmail => email != null && email!.trim().isNotEmpty;
  bool get hasUrl => url != null && url!.trim().isNotEmpty;
  bool get hasLaunchTarget => hasPhone || hasEmail || hasUrl;

  int get actionCount =>
      (hasPhone ? 1 : 0) + (hasEmail ? 1 : 0) + (hasUrl ? 1 : 0);

  String get displaySubtitle {
    final noteText = note?.trim() ?? '';
    if (noteText.isNotEmpty) return noteText;
    final nameText = name?.trim() ?? '';
    final phoneText = phone?.trim() ?? '';
    if (nameText.isNotEmpty && phoneText.isNotEmpty) {
      return '$nameText • $phoneText';
    }
    if (nameText.isNotEmpty) return nameText;
    if (phoneText.isNotEmpty) return phoneText;
    final emailText = email?.trim() ?? '';
    if (emailText.isNotEmpty) return emailText;
    return url?.trim() ?? '';
  }

  static String? validate({
    required String title,
    String? phone,
    String? email,
    String? url,
  }) {
    if (title.trim().isEmpty) return 'Title required';
    final hasPhone = phone != null && phone.trim().isNotEmpty;
    final hasEmail = email != null && email.trim().isNotEmpty;
    final hasUrl = url != null && url.trim().isNotEmpty;
    if (!hasPhone && !hasEmail && !hasUrl) {
      return 'Add a phone, email, or link';
    }
    return null;
  }

  Map<String, dynamic> toFirestore() => {
        'title': title.trim(),
        'name': name?.trim() ?? '',
        'phone': phone?.trim() ?? '',
        'email': email?.trim() ?? '',
        'url': url?.trim() ?? '',
        'note': note?.trim() ?? '',
        'sectionId': sectionId,
        'sortOrder': sortOrder,
        'iconKey': iconKey,
      };

  factory ContactEntry.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) =>
      ContactEntry(
        id: id,
        title: data['title'] as String? ?? '',
        name: nonEmptyString(data['name']),
        phone: nonEmptyString(data['phone']),
        email: nonEmptyString(data['email']),
        url: nonEmptyString(data['url']),
        note: nonEmptyString(data['note']),
        sectionId: data['sectionId'] as String? ?? '',
        sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
        iconKey: data['iconKey'] as String? ?? 'person',
      );

  ContactEntry copyWith({
    String? id,
    String? title,
    Object? name = _unset,
    Object? phone = _unset,
    Object? email = _unset,
    Object? url = _unset,
    Object? note = _unset,
    String? sectionId,
    int? sortOrder,
    String? iconKey,
  }) =>
      ContactEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        name: identical(name, _unset) ? this.name : name as String?,
        phone: identical(phone, _unset) ? this.phone : phone as String?,
        email: identical(email, _unset) ? this.email : email as String?,
        url: identical(url, _unset) ? this.url : url as String?,
        note: identical(note, _unset) ? this.note : note as String?,
        sectionId: sectionId ?? this.sectionId,
        sortOrder: sortOrder ?? this.sortOrder,
        iconKey: iconKey ?? this.iconKey,
      );
}

class ContactGroup {
  const ContactGroup({this.section, required this.entries});

  final ContactSection? section;
  final List<ContactEntry> entries;
}

class ContactsCatalog {
  const ContactsCatalog({
    this.sections = const [],
    this.entries = const [],
  });

  final List<ContactSection> sections;
  final List<ContactEntry> entries;

  bool get isEmpty => sections.isEmpty && entries.isEmpty;

  Color colorFor(ContactEntry entry, ContactSection? section) {
    if (section != null) return section.color;
    return AppTheme.primaryColor;
  }

  ContactSection? sectionById(String id) {
    if (id.isEmpty) return null;
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  int nextEntrySortOrder(String sectionId) {
    final inSection = entries.where((e) => e.sectionId == sectionId);
    if (inSection.isEmpty) return 10;
    return inSection
            .map((e) => e.sortOrder)
            .reduce((a, b) => a > b ? a : b) +
        10;
  }

  int nextSectionSortOrder() {
    if (sections.isEmpty) return 10;
    return sections.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) +
        10;
  }

  /// Ungrouped contacts first, then sections in [sortOrder]. Empty sections
  /// are included so admin can still add to them.
  List<ContactGroup> grouped() {
    final sortedSections = [...sections]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final knownIds = <String>{for (final s in sortedSections) s.id};

    final bySection = <String, List<ContactEntry>>{};
    final ungrouped = <ContactEntry>[];
    for (final entry in entries) {
      if (entry.sectionId.isEmpty || !knownIds.contains(entry.sectionId)) {
        ungrouped.add(entry);
      } else {
        bySection.putIfAbsent(entry.sectionId, () => []).add(entry);
      }
    }
    ungrouped.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final list in bySection.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final groups = <ContactGroup>[];
    if (ungrouped.isNotEmpty) {
      groups.add(ContactGroup(section: null, entries: ungrouped));
    }
    for (final section in sortedSections) {
      groups.add(
        ContactGroup(
          section: section,
          entries: bySection[section.id] ?? const [],
        ),
      );
    }
    return groups;
  }

  factory ContactsCatalog.defaults() => ContactsCatalog(
        sections: defaultContactSections,
        entries: defaultContactEntries,
      );
}

const defaultContactSections = <ContactSection>[
  ContactSection(
    id: 'section_hr_pay',
    name: 'HR & Pay',
    sortOrder: 10,
    iconKey: 'paid',
    colorArgb: 0xFFFF9800,
  ),
  ContactSection(
    id: 'section_depot_mgmt',
    name: 'Depot Management',
    sortOrder: 20,
    iconKey: 'people',
    colorArgb: 0xFF3F51B5,
  ),
  ContactSection(
    id: 'section_controllers',
    name: 'Controllers',
    sortOrder: 30,
    iconKey: 'headset_mic',
    colorArgb: 0xFF009688,
  ),
  ContactSection(
    id: 'section_services',
    name: 'Services',
    sortOrder: 40,
    iconKey: 'support_agent',
    colorArgb: 0xFF26A69A,
  ),
  ContactSection(
    id: 'section_medical',
    name: 'Medical',
    sortOrder: 50,
    iconKey: 'medical_services',
    colorArgb: 0xFF9C27B0,
  ),
];

const defaultContactEntries = <ContactEntry>[
  ContactEntry(
    id: 'contact_phibsboro',
    title: 'Phibsboro Depot',
    phone: '01 703 3462',
    sectionId: '',
    sortOrder: 10,
    iconKey: 'business',
  ),
  ContactEntry(
    id: 'contact_people_xd',
    title: 'People XD (Core HR)',
    url:
        'https://my.corehr.com/pls/coreportal_dbp/cp_por_public_main_page.display_login_page',
    note: 'Payslips, holiday allowance & more',
    sectionId: 'section_hr_pay',
    sortOrder: 10,
    iconKey: 'paid',
  ),
  ContactEntry(
    id: 'contact_depot_manager',
    title: 'Depot Manager',
    name: 'Tim Fitzgibbons',
    email: 'tim.fitzgibbons@dublinbus.ie',
    sectionId: 'section_depot_mgmt',
    sortOrder: 10,
    iconKey: 'badge',
  ),
  ContactEntry(
    id: 'contact_depot_admin',
    title: 'Depot Administrator',
    name: 'Ed Moyles',
    email: 'ed.moyles@dublinbus.ie',
    sectionId: 'section_depot_mgmt',
    sortOrder: 20,
    iconKey: 'admin_panel_settings',
  ),
  ContactEntry(
    id: 'contact_39s',
    title: '39s Controller',
    phone: '01 703 1141',
    sectionId: 'section_controllers',
    sortOrder: 10,
    iconKey: 'support_agent',
  ),
  ContactEntry(
    id: 'contact_23_24',
    title: '23/24 Controller',
    phone: '01 703 1145',
    sectionId: 'section_controllers',
    sortOrder: 20,
    iconKey: 'support_agent',
  ),
  ContactEntry(
    id: 'contact_cs',
    title: 'Cs Controller',
    phone: '01 703 1136',
    sectionId: 'section_controllers',
    sortOrder: 30,
    iconKey: 'support_agent',
  ),
  ContactEntry(
    id: 'contact_lost_property',
    title: 'Lost Property',
    phone: '01 703 1321',
    sectionId: 'section_services',
    sortOrder: 10,
    iconKey: 'inventory',
  ),
  ContactEntry(
    id: 'contact_clerical',
    title: 'Clerical Office',
    name: 'John',
    phone: '01 703 3244',
    sectionId: 'section_services',
    sortOrder: 20,
    iconKey: 'description',
  ),
  ContactEntry(
    id: 'contact_cmo',
    title: 'CMO',
    phone: '01 703 1338',
    sectionId: 'section_medical',
    sortOrder: 10,
    iconKey: 'medical_services',
  ),
];
