import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spdrivercalendar/core/widgets/correction_note.dart';
import 'package:spdrivercalendar/features/contacts/contact_models.dart';
import 'package:spdrivercalendar/features/contacts/widgets/contact_card.dart';
import 'package:spdrivercalendar/services/contacts_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, this.catalogOverride});

  /// When set (tests), skip Firestore and render this catalog.
  @visibleForTesting
  final ContactsCatalog? catalogOverride;

  @override
  ContactsPageState createState() => ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBottomFade = true;

  Future<void> _launchPhoneCall(String phoneNumber, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Uri phoneUri = Uri(scheme: 'tel', path: digitsForTel(phoneNumber));
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call to $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error launching phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final normalized = normalizeContactUrl(url);
    if (normalized == null) return;
    final Uri uri = Uri.parse(normalized);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error opening link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchEmail(String email, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Could not launch email to $email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error launching email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_updateScrollIndicator);
      if (_scrollController.hasClients) {
        _updateScrollIndicator();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicator);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollIndicator() {
    if (!_scrollController.hasClients) return;

    final metrics = _scrollController.position;
    final maxScroll = metrics.maxScrollExtent;
    final currentScroll = metrics.pixels;
    final isAtBottom = currentScroll >= maxScroll - 20 || maxScroll <= 0;

    if (_showBottomFade != !isAtBottom) {
      setState(() {
        _showBottomFade = !isAtBottom;
      });
    }
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.only(
        top: isSmallScreen ? 20 : 24,
        bottom: isSmallScreen ? 10 : 12,
        left: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalog(BuildContext context, ContactsCatalog catalog) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 600;
    final children = <Widget>[];

    for (final group in catalog.grouped()) {
      if (group.entries.isEmpty) continue;
      final section = group.section;
      if (section != null) {
        children.add(
          _buildSectionHeader(
            section.name,
            ContactIcons.data(section.iconKey),
            section.color,
            context,
          ),
        );
      }
      for (final entry in group.entries) {
        final color = catalog.colorFor(entry, section);
        children.add(
          ContactCard(
            key: ValueKey('contact-card-${entry.id}'),
            entry: entry,
            color: color,
            onCall: entry.hasPhone
                ? () => _launchPhoneCall(entry.phone!, context)
                : null,
            onEmail: entry.hasEmail
                ? () => _launchEmail(entry.email!, context)
                : null,
            onOpenLink:
                entry.hasUrl ? () => _launchUrl(entry.url!, context) : null,
          ),
        );
      }
    }

    children.insert(
      0,
      CorrectionNote(
        pageLabel: 'the contacts page',
        padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      ),
    );
    children.add(SizedBox(height: isSmallScreen ? 12 : 16));

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: theme.brightness == Brightness.dark
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ],
                  ),
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(3),
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: 8,
              ),
              children: children,
            ),
          ),
        ),
        if (_showBottomFade)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important Contacts'),
        elevation: 0,
      ),
      body: widget.catalogOverride != null
          ? _buildCatalog(context, widget.catalogOverride!)
          : StreamBuilder<ContactsCatalog>(
              stream: ContactsService.watchCatalog(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final catalog = snapshot.hasError || !snapshot.hasData
                    ? ContactsCatalog.defaults()
                    : snapshot.data!;
                return _buildCatalog(context, catalog);
              },
            ),
    );
  }
}
