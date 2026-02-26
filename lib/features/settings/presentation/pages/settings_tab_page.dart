import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SettingsTabPage extends StatefulWidget {
  const SettingsTabPage({super.key});

  @override
  State<SettingsTabPage> createState() => _SettingsTabPageState();
}

class _SettingsTabPageState extends State<SettingsTabPage> {
  bool _twoFactorEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _weeklyDigest = true;

  String _language = 'English';
  String _timezone = 'Asia/Qatar (GMT+3)';

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
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildProfileCard()),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: isCompact ? 3 : 2,
                          child: _buildQuickActionsCard(),
                        ),
                      ],
                    ),
              const SizedBox(height: 12),
              _buildSecuritySection(isNarrow),
              const SizedBox(height: 12),
              _buildNotificationSection(isNarrow),
              const SizedBox(height: 12),
              _buildPreferenceSection(isNarrow),
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
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE6EDF7),
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF4B5563),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Manager',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'manager@redrose.com',
                      style: TextStyle(
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
                onTap: () => _toast('Profile editor opened'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE9EDF3)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _InfoChip(label: 'Role', value: 'Sales Manager'),
              _InfoChip(label: 'Phone', value: '+974 5500 1122'),
              _InfoChip(label: 'Region', value: 'Doha'),
              _InfoChip(label: 'Department', value: 'Commercial'),
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
            onTap: () => _toast('Permission manager opened'),
          ),
          _actionTile(
            icon: Iconsax.notification,
            title: 'Notification Rules',
            subtitle: 'Control alerts for orders, targets, and stock',
            onTap: () => _toast('Notification rules opened'),
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
          subtitle: 'Browser: Chrome on macOS • Last active now',
          trailing: _outlineActionButton(
            icon: Iconsax.close_circle,
            label: isNarrow ? 'Revoke' : 'Revoke Other Devices',
            onTap: () => _toast('Other sessions revoked'),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(bool isNarrow) {
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

  Widget _buildPreferenceSection(bool isNarrow) {
    return _sectionCard(
      title: 'Preferences',
      subtitle: 'Configure regional and display preferences.',
      children: [
        _settingRow(
          icon: Iconsax.money,
          title: 'Currency',
          subtitle: 'Default transaction currency',
          trailing: const _Pill(text: 'QAR'),
        ),
        _settingRow(
          icon: Iconsax.language_square,
          title: 'Language',
          subtitle: 'Interface language',
          trailing: PopupMenuButton<String>(
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
          const Text(
            'Sensitive account actions. Use carefully.',
            style: TextStyle(
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
                onPressed: () => _toast('Account deactivation request started'),
                icon: const Icon(Iconsax.user_remove),
                label: const Text('Deactivate Account'),
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

  void _confirmResetPassword() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: const Text(
            'Send a password reset link to manager@redrose.com?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toast('Password reset link sent');
              },
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from this account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toast('Logged out');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
