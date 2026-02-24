import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  ContactsPageState createState() => ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBottomFade = true;

  // Helper function to launch phone calls
  Future<void> _launchPhoneCall(String phoneNumber, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'\s+'), ''));
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

  // Helper function to launch URL in external browser
  Future<void> _launchUrl(String url, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
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

  // Helper function to launch email
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
      if (_scrollController.hasClients) {
        _updateScrollIndicator();
        _scrollController.addListener(_updateScrollIndicator);
      } else {
        _scrollController.addListener(_updateScrollIndicator);
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
    
    // Show fade if we're not at the bottom (with some threshold)
    final isAtBottom = currentScroll >= maxScroll - 20 || maxScroll <= 0;
    
    if (_showBottomFade != !isAtBottom) {
      setState(() {
        _showBottomFade = !isAtBottom;
      });
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.only(
        top: isSmallScreen ? 20 : 24,
        bottom: isSmallScreen ? 10 : 12,
        left: 4,
      ),
      child: Row(
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
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required BuildContext context,
    IconData? actionIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: isSmallScreen ? 20 : 24),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : null,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: isSmallScreen ? 12 : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                actionIcon ?? Icons.phone,
                size: isSmallScreen ? 20 : 22,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Important Contacts'),
        elevation: 0,
      ),
      body: Stack(
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
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                children: [
            // Main Depot Contact - number 1, where we work from
            _buildContactCard(
              title: 'Phibsboro Depot',
              subtitle: '01 703 3462',
              icon: Icons.business,
              iconColor: AppTheme.primaryColor,
              onTap: () => _launchPhoneCall('017033462', context),
              context: context,
              actionIcon: Icons.phone,
            ),

            // HR & Pay Section
            _buildSectionHeader(
              'HR & Pay',
              Icons.paid,
              Colors.orange,
              context,
            ),
            _buildContactCard(
              title: 'People XD (Core HR)',
              subtitle: 'Payslips, holiday allowance & more',
              icon: Icons.paid,
              iconColor: Colors.orange,
              onTap: () => _launchUrl(
                'https://my.corehr.com/pls/coreportal_dbp/cp_por_public_main_page.display_login_page',
                context,
              ),
              context: context,
              actionIcon: Icons.open_in_new,
            ),
            
            // Depot Management Section
            _buildSectionHeader(
              'Depot Management',
              Icons.people,
              Colors.indigo,
              context,
            ),
            _buildContactCard(
              title: 'Depot Manager',
              subtitle: 'Tim Fitzgibbons',
              icon: Icons.badge,
              iconColor: Colors.indigo,
              onTap: () => _launchEmail('tim.fitzgibbons@dublinbus.ie', context),
              context: context,
              actionIcon: Icons.email,
            ),
            _buildContactCard(
              title: 'Depot Administrator',
              subtitle: 'Ed Moyles',
              icon: Icons.admin_panel_settings,
              iconColor: Colors.indigo,
              onTap: () => _launchEmail('ed.moyles@dublinbus.ie', context),
              context: context,
              actionIcon: Icons.email,
            ),
            
            // Controllers Section
            _buildSectionHeader(
              'Controllers',
              Icons.headset_mic,
              Colors.teal,
              context,
            ),
            _buildContactCard(
              title: '39s Controller',
              subtitle: '01 703 1141',
              icon: Icons.support_agent,
              iconColor: Colors.teal,
              onTap: () => _launchPhoneCall('017031141', context),
              context: context,
              actionIcon: Icons.phone,
            ),
            _buildContactCard(
              title: '23/24 Controller',
              subtitle: '01 703 1145',
              icon: Icons.support_agent,
              iconColor: Colors.teal,
              onTap: () => _launchPhoneCall('017031145', context),
              context: context,
              actionIcon: Icons.phone,
            ),
            _buildContactCard(
              title: 'Cs Controller',
              subtitle: '01 703 1136',
              icon: Icons.support_agent,
              iconColor: Colors.teal,
              onTap: () => _launchPhoneCall('017031136', context),
              context: context,
              actionIcon: Icons.phone,
            ),
            
            // Services Section
            _buildSectionHeader(
              'Services',
              Icons.support_agent,
              AppTheme.secondaryColor,
              context,
            ),
            _buildContactCard(
              title: 'Lost Property',
              subtitle: '01 703 1321',
              icon: Icons.inventory_2_outlined,
              iconColor: AppTheme.secondaryColor,
              onTap: () => _launchPhoneCall('017031321', context),
              context: context,
              actionIcon: Icons.phone,
            ),
            _buildContactCard(
              title: 'Clerical Office',
              subtitle: 'John • 01 703 3244',
              icon: Icons.description,
              iconColor: AppTheme.secondaryColor,
              onTap: () => _launchPhoneCall('017033244', context),
              context: context,
              actionIcon: Icons.phone,
            ),
            
            // Medical Section
            _buildSectionHeader(
              'Medical',
              Icons.medical_services,
              Colors.purple,
              context,
            ),
            _buildContactCard(
              title: 'CMO',
              subtitle: '01 703 1308',
              icon: Icons.medical_services,
              iconColor: Colors.purple,
              onTap: () => _launchPhoneCall('017031308', context),
              context: context,
              actionIcon: Icons.phone,
            ),
            
            SizedBox(height: isSmallScreen ? 12 : 16),
          ],
        ),
      ),
            ),
          // Scroll indicator - subtle shadow at bottom when scrollable
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
      ),
    );
  }
}
