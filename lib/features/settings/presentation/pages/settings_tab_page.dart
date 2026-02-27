import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xls;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:products_catelogs/core/constants/firestore_collections.dart';
import 'package:products_catelogs/core/utils/file_download.dart';

class SettingsTabPage extends StatefulWidget {
  final VoidCallback? onLogout;

  const SettingsTabPage({super.key, this.onLogout});

  @override
  State<SettingsTabPage> createState() => _SettingsTabPageState();
}

class _SettingsTabPageState extends State<SettingsTabPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat _reportDateFormat = DateFormat('yyyy-MM-dd HH:mm');

  bool _isSavingProfile = false;
  bool _isExportingReport = false;
  String _whatsAppOrderNumber = '+97455001122';

  bool _twoFactorEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _weeklyDigest = true;
  bool _deactivated = false;

  String _currency = 'QAR';
  String _language = 'English';
  String _timezone = 'Asia/Qatar (GMT+3)';

  String _fullName = 'Sales Manager';
  String _email = 'manager@redrose.com';
  String _role = 'Sales Manager';
  String _phone = '+974 5500 1122';
  String _region = 'Doha';
  String _department = 'Commercial';

  int _failedOrderAlertMinutes = 10;
  int _lowStockThreshold = 20;

  final Map<String, bool> _permissions = {
    'Products': true,
    'Orders': true,
    'Staff': false,
    'Settings': true,
  };

  final List<_SessionInfo> _sessions = [
    const _SessionInfo(
      id: 's1',
      device: 'Chrome on macOS',
      location: 'Doha',
      isCurrent: true,
      lastActive: 'Now',
    ),
    const _SessionInfo(
      id: 's2',
      device: 'Safari on iPhone',
      location: 'Doha',
      isCurrent: false,
      lastActive: '2 hours ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null || !mounted) return;
    setState(() {
      _fullName = _valueOr(data['fullName'], fallback: _fullName);
      _email = _valueOr(data['email'], fallback: _email);
      _role = _valueOr(data['role'], fallback: _role);
      _phone = _valueOr(data['phone'], fallback: _phone);
      _region = _valueOr(data['region'], fallback: _region);
      _department = _valueOr(data['department'], fallback: _department);
      _whatsAppOrderNumber = _valueOr(
        data['whatsappOrderNumber'],
        fallback: _whatsAppOrderNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;
        final isNarrow = constraints.maxWidth < 840;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              isNarrow
                  ? Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 12),
                        _buildQuickActionsCard(),
                      ],
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: _buildProfileCard()),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: isCompact ? 3 : 2,
                            child: _buildQuickActionsCard(),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 12),
              _buildSecuritySection(isNarrow),
              const SizedBox(height: 12),
              _buildNotificationSection(),
              const SizedBox(height: 12),
              _buildPreferenceSection(),
              const SizedBox(height: 12),
              _buildReportsAndIntegrationSection(),
              const SizedBox(height: 12),
              _buildDangerZone(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 30,
            height: 1.1,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Manage account profile, security, notifications, and access controls.',
          style: TextStyle(
            color: Color(0xFF8A94A6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE6EDF7),
                child: Text(
                  _initials(_fullName),
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _email,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _outlineActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: _editProfile,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE9EDF3)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: 'Role', value: _role),
              _InfoChip(label: 'Phone', value: _phone),
              _InfoChip(label: 'Region', value: _region),
              _InfoChip(label: 'Department', value: _department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _actionTile(
            icon: Iconsax.lock,
            title: 'Reset Password',
            subtitle: 'Send reset link and force new credentials',
            onTap: _confirmResetPassword,
          ),
          _actionTile(
            icon: Iconsax.profile_2user,
            title: 'Manage Team Permissions',
            subtitle: 'Roles and module access controls',
            onTap: _managePermissions,
          ),
          _actionTile(
            icon: Iconsax.notification,
            title: 'Notification Rules',
            subtitle: 'Control alerts for orders, targets, and stock',
            onTap: _manageNotificationRules,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7ECF3)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF5A6574)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8A94A6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF8E99A9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection(bool isNarrow) {
    return _sectionCard(
      title: 'Security',
      subtitle: 'Protect your account and control active sessions.',
      children: [
        _settingRow(
          icon: Iconsax.shield_tick,
          title: 'Two-Factor Authentication',
          subtitle: 'Require OTP verification during login',
          trailing: Switch(
            value: _twoFactorEnabled,
            onChanged: (value) => setState(() => _twoFactorEnabled = value),
          ),
        ),
        _settingRow(
          icon: Iconsax.password_check,
          title: 'Reset Password',
          subtitle: 'Recommended every 90 days',
          trailing: _outlineActionButton(
            icon: Iconsax.key,
            label: 'Reset',
            onTap: _confirmResetPassword,
          ),
        ),
        _settingRow(
          icon: Iconsax.monitor,
          title: 'Active Sessions',
          subtitle: _sessionSubtitle,
          trailing: _outlineActionButton(
            icon: Iconsax.close_circle,
            label: isNarrow ? 'Manage' : 'Manage Sessions',
            onTap: _manageSessions,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _sectionCard(
      title: 'Notifications',
      subtitle: 'Choose how you receive operational and sales alerts.',
      children: [
        _settingRow(
          icon: Iconsax.sms,
          title: 'Email Notifications',
          subtitle: 'Order status updates and account activity',
          trailing: Switch(
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
        ),
        _settingRow(
          icon: Iconsax.message,
          title: 'SMS Notifications',
          subtitle: 'Critical alerts for failed payments and stock issues',
          trailing: Switch(
            value: _smsNotifications,
            onChanged: (value) => setState(() => _smsNotifications = value),
          ),
        ),
        _settingRow(
          icon: Iconsax.calendar,
          title: 'Weekly Summary',
          subtitle: 'Sales performance digest every Saturday',
          trailing: Switch(
            value: _weeklyDigest,
            onChanged: (value) => setState(() => _weeklyDigest = value),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceSection() {
    return _sectionCard(
      title: 'Preferences',
      subtitle: 'Configure regional and display preferences.',
      children: [
        _settingRow(
          icon: Iconsax.money,
          title: 'Currency',
          subtitle: 'Default transaction currency',
          trailing: PopupMenuButton<String>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x1A0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            offset: const Offset(0, 42),
            onSelected: (value) => setState(() => _currency = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'QAR', child: Text('QAR')),
              PopupMenuItem(value: 'USD', child: Text('USD')),
            ],
            child: _pillButton(_currency),
          ),
        ),
        _settingRow(
          icon: Iconsax.language_square,
          title: 'Language',
          subtitle: 'Interface language',
          trailing: PopupMenuButton<String>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x1A0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            offset: const Offset(0, 42),
            onSelected: (value) => setState(() => _language = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'English', child: Text('English')),
              PopupMenuItem(value: 'Arabic', child: Text('Arabic')),
            ],
            child: _pillButton(_language),
          ),
        ),
        _settingRow(
          icon: Iconsax.timer_1,
          title: 'Timezone',
          subtitle: 'Used for reports and schedules',
          trailing: PopupMenuButton<String>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0x1A0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            offset: const Offset(0, 42),
            onSelected: (value) => setState(() => _timezone = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'Asia/Qatar (GMT+3)',
                child: Text('Asia/Qatar (GMT+3)'),
              ),
              PopupMenuItem(value: 'UTC (GMT+0)', child: Text('UTC (GMT+0)')),
            ],
            child: _pillButton(_timezone),
          ),
        ),
        _settingRow(
          icon: Iconsax.message,
          title: 'Order WhatsApp Number',
          subtitle: 'Current: $_whatsAppOrderNumber',
          trailing: _outlineActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: _configureWhatsAppNumber,
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF7D2D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              color: Color(0xFFB4232A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _deactivated
                ? 'Account is currently marked as deactivated.'
                : 'Sensitive account actions. Use carefully.',
            style: const TextStyle(
              color: Color(0xFF9E4A53),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB4232A),
                  side: const BorderSide(color: Color(0xFFF1AAB1)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _toggleDeactivateAccount,
                icon: Icon(
                  _deactivated ? Iconsax.user_add : Iconsax.user_remove,
                ),
                label: Text(
                  _deactivated ? 'Reactivate Account' : 'Deactivate Account',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB4232A),
                  side: const BorderSide(color: Color(0xFFF1AAB1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsAndIntegrationSection() {
    return _sectionCard(
      title: 'Reports & Integration',
      subtitle: 'Stock Excel exports and WhatsApp order routing.',
      children: [
        _settingRow(
          icon: Iconsax.message,
          title: 'WhatsApp Integration',
          subtitle: 'Current: $_whatsAppOrderNumber',
          trailing: _outlineActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: _configureWhatsAppNumber,
          ),
        ),
        _settingRow(
          icon: Iconsax.document_download,
          title: 'In-Stock Report',
          subtitle: 'Generate Excel for products with available stock',
          trailing: _outlineActionButton(
            icon: Icons.download_rounded,
            label: 'Export',
            onTap: _isExportingReport ? () {} : () => _exportStockReport(false),
          ),
        ),
        _settingRow(
          icon: Iconsax.warning_2,
          title: 'Out-of-Stock Report',
          subtitle: 'Generate Excel for products with zero stock',
          trailing: _outlineActionButton(
            icon: Icons.download_rounded,
            label: 'Export',
            onTap: _isExportingReport ? () {} : () => _exportStockReport(true),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8A94A6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, color: Color(0xFFE9EDF3)),
          ],
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF556070), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8A94A6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }

  Widget _outlineActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD9DFE8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _pillButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9DFE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }

  String get _sessionSubtitle {
    final otherCount = _sessions.where((e) => !e.isCurrent).length;
    if (otherCount == 0) return 'Only current browser session is active';
    return '$otherCount other session(s) active';
  }

  Future<void> _editProfile() async {
    final fullNameController = TextEditingController(text: _fullName);
    final emailController = TextEditingController(text: _email);
    final roleController = TextEditingController(text: _role);
    final phoneController = TextEditingController(text: _phone);
    final regionController = TextEditingController(text: _region);
    final departmentController = TextEditingController(text: _department);
    final formKey = GlobalKey<FormState>();

    final updated = await _showSideSheet<bool>(
      title: 'Edit Profile',
      body: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: regionController,
              decoration: const InputDecoration(labelText: 'Region'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: departmentController,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (!(formKey.currentState?.validate() ?? false)) return;
            setState(() {
              _fullName = fullNameController.text.trim();
              _email = emailController.text.trim();
              _role = roleController.text.trim();
              _phone = phoneController.text.trim();
              _region = regionController.text.trim();
              _department = departmentController.text.trim();
            });
            await _saveUserProfile();
            if (!mounted) return;
            navigator.pop(true);
          },
          child: const Text('Save'),
        ),
      ],
    );

    if (updated == true) _toast('Profile updated');
  }

  Future<void> _confirmResetPassword() async {
    final shouldSend = await _showSideSheet<bool>(
      title: 'Reset Password',
      body: Text('Send a password reset link to $_email?'),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Send Link'),
        ),
      ],
    );
    if (shouldSend == true) _toast('Password reset link sent');
  }

  Future<void> _managePermissions() async {
    final localPermissions = Map<String, bool>.from(_permissions);
    final saved = await _showSideSheet<bool>(
      title: 'Team Permissions',
      body: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: localPermissions.keys.map((module) {
              return SwitchListTile(
                dense: true,
                title: Text(module),
                value: localPermissions[module] ?? false,
                onChanged: (value) {
                  setDialogState(() => localPermissions[module] = value);
                },
              );
            }).toList(),
          );
        },
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              _permissions
                ..clear()
                ..addAll(localPermissions);
            });
            Navigator.of(context).pop(true);
          },
          child: const Text('Save'),
        ),
      ],
    );
    if (saved == true) _toast('Permissions updated');
  }

  Future<void> _manageNotificationRules() async {
    var failedMinutes = _failedOrderAlertMinutes;
    var lowStock = _lowStockThreshold;
    final saved = await _showSideSheet<bool>(
      title: 'Notification Rules',
      body: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Failed order alert after (minutes)'),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: failedMinutes.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) failedMinutes = parsed;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(child: Text('Low stock threshold (units)')),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: lowStock.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) lowStock = parsed;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                dense: true,
                title: const Text('Email Notifications'),
                value: _emailNotifications,
                onChanged: (value) {
                  setDialogState(() => _emailNotifications = value);
                },
              ),
              SwitchListTile(
                dense: true,
                title: const Text('SMS Notifications'),
                value: _smsNotifications,
                onChanged: (value) {
                  setDialogState(() => _smsNotifications = value);
                },
              ),
            ],
          );
        },
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              _failedOrderAlertMinutes = failedMinutes;
              _lowStockThreshold = lowStock;
            });
            Navigator.of(context).pop(true);
          },
          child: const Text('Save'),
        ),
      ],
    );
    if (saved == true) _toast('Notification rules saved');
  }

  Future<void> _manageSessions() async {
    final saved = await _showSideSheet<bool>(
      title: 'Active Sessions',
      body: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: _sessions.map((session) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  session.isCurrent ? Icons.laptop_mac : Icons.phone_iphone,
                ),
                title: Text(session.device),
                subtitle: Text('${session.location} • ${session.lastActive}'),
                trailing: session.isCurrent
                    ? const Text('Current')
                    : TextButton(
                        onPressed: () {
                          setDialogState(() {
                            _sessions.removeWhere((e) => e.id == session.id);
                          });
                        },
                        child: const Text('Revoke'),
                      ),
              );
            }).toList(),
          );
        },
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {});
            Navigator.of(context).pop(true);
          },
          child: const Text('Apply'),
        ),
      ],
    );
    if (saved == true) _toast('Sessions updated');
  }

  Future<void> _toggleDeactivateAccount() async {
    if (_deactivated) {
      setState(() => _deactivated = false);
      _toast('Account reactivated');
      return;
    }

    final controller = TextEditingController();
    final confirmed = await _showSideSheet<bool>(
      title: 'Deactivate Account',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type DEACTIVATE to confirm.'),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'DEACTIVATE'),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(controller.text.trim().toUpperCase() == 'DEACTIVATE');
          },
          child: const Text('Confirm'),
        ),
      ],
    );

    if (confirmed == true) {
      setState(() => _deactivated = true);
      _toast('Account deactivated');
    } else if (confirmed == false) {
      _toast('Deactivation cancelled');
    }
  }

  Future<void> _configureWhatsAppNumber() async {
    final controller = TextEditingController(text: _whatsAppOrderNumber);
    final updated = await _showSideSheet<bool>(
      title: 'Order WhatsApp Number',
      body: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'WhatsApp Number',
          hintText: '+97455001122',
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final value = controller.text.trim();
            if (value.isEmpty) return;
            setState(() => _whatsAppOrderNumber = value);
            await _saveUserProfile();
            if (!mounted) return;
            navigator.pop(true);
          },
          child: const Text('Save'),
        ),
      ],
    );
    if (updated == true) {
      _toast('WhatsApp number updated');
    }
  }

  Future<void> _saveUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (_isSavingProfile) return;
    setState(() => _isSavingProfile = true);
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'fullName': _fullName,
            'email': _email,
            'role': _role,
            'phone': _phone,
            'region': _region,
            'department': _department,
            'whatsappOrderNumber': _whatsAppOrderNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error) {
      if (mounted) {
        _toast('Failed to save settings: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _exportStockReport(bool outOfStockOnly) async {
    if (_isExportingReport) return;
    setState(() => _isExportingReport = true);
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.products)
          .get();
      final rows =
          snapshot.docs
              .map(ProductReportRow.fromDoc)
              .whereType<ProductReportRow>()
              .where(
                (row) => outOfStockOnly
                    ? row.stockInBaseUnit <= 0
                    : row.stockInBaseUnit > 0,
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      final excelBytes = _buildStockReportExcel(
        rows: rows,
        outOfStockOnly: outOfStockOnly,
      );
      if (excelBytes == null || excelBytes.isEmpty) {
        _toast('Failed to generate report.');
        return;
      }

      final reportType = outOfStockOnly ? 'out_of_stock' : 'in_stock';
      final fileName =
          'products_${reportType}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      final saved = await downloadBytesFile(
        bytes: excelBytes,
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!saved) {
        _toast('File download is only supported on web in this build.');
        return;
      }
      _toast('Excel report generated: $fileName');
    } catch (error) {
      _toast('Failed to export report: $error');
    } finally {
      if (mounted) {
        setState(() => _isExportingReport = false);
      }
    }
  }

  List<int>? _buildStockReportExcel({
    required List<ProductReportRow> rows,
    required bool outOfStockOnly,
  }) {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Report'];
    sheet.appendRow([
      xls.TextCellValue('Product Code'),
      xls.TextCellValue('Product Name'),
      xls.TextCellValue('Category'),
      xls.TextCellValue('Stock (Base Unit)'),
      xls.TextCellValue('Base Unit'),
      xls.TextCellValue('Price (QAR)'),
      xls.TextCellValue('Status'),
      xls.TextCellValue('Generated At'),
    ]);

    final generatedAt = _reportDateFormat.format(DateTime.now());
    for (final row in rows) {
      sheet.appendRow([
        xls.TextCellValue(row.code),
        xls.TextCellValue(row.name),
        xls.TextCellValue(row.category),
        xls.DoubleCellValue(row.stockInBaseUnit),
        xls.TextCellValue(row.baseUnit),
        xls.DoubleCellValue(row.displayPriceQar),
        xls.TextCellValue(outOfStockOnly ? 'Out of stock' : 'In stock'),
        xls.TextCellValue(generatedAt),
      ]);
    }
    return excel.encode();
  }

  void _confirmLogout() {
    _showSideSheet<void>(
      title: 'Logout',
      body: const Text('Are you sure you want to logout from this account?'),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            final onLogout = widget.onLogout;
            if (onLogout != null) {
              onLogout();
            } else {
              _toast('Logged out');
            }
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }

  Future<T?> _showSideSheet<T>({
    required String title,
    required Widget body,
    List<Widget> actions = const [],
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: const Color(0x400F172A),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width > 1080 ? 500.0 : (width > 720 ? 440.0 : width);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: sheetWidth,
                height: double.infinity,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Iconsax.close_circle, size: 20),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: body,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Wrap(spacing: 10, runSpacing: 10, children: actions),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _valueOr(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class ProductReportRow {
  final String code;
  final String name;
  final String category;
  final double stockInBaseUnit;
  final String baseUnit;
  final double displayPriceQar;

  const ProductReportRow({
    required this.code,
    required this.name,
    required this.category,
    required this.stockInBaseUnit,
    required this.baseUnit,
    required this.displayPriceQar,
  });

  static ProductReportRow? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final category = _mapOf(data['category']);
    final baseUnit = _mapOf(data['baseUnit']);
    final inventory = _mapOf(data['inventory']);
    final metrics = _mapOf(data['metrics']);
    final productCode =
        (data['productCode'] as String?)?.trim().isNotEmpty == true
        ? (data['productCode'] as String).trim()
        : doc.id;

    return ProductReportRow(
      code: productCode,
      name: ((data['productName'] as String?) ?? '').trim().isEmpty
          ? 'Unnamed Product'
          : (data['productName'] as String).trim(),
      category: ((category['name'] as String?) ?? '').trim().isEmpty
          ? 'Uncategorized'
          : (category['name'] as String).trim(),
      stockInBaseUnit:
          _doubleOf(inventory['availableQtyBaseUnit']) ??
          _doubleOf(inventory['baseUnitQty']) ??
          0,
      baseUnit: ((baseUnit['name'] as String?) ?? '').trim().isEmpty
          ? 'Piece'
          : (baseUnit['name'] as String).trim(),
      displayPriceQar: _doubleOf(metrics['displayPriceQar']) ?? 0,
    );
  }

  static Map<String, dynamic> _mapOf(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }

  static double? _doubleOf(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionInfo {
  final String id;
  final String device;
  final String location;
  final bool isCurrent;
  final String lastActive;

  const _SessionInfo({
    required this.id,
    required this.device,
    required this.location,
    required this.isCurrent,
    required this.lastActive,
  });
}
