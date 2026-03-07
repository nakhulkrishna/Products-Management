import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/features/auth/application/auth_providers.dart';
import 'package:products_catelogs/features/auth/presentation/pages/auth_page.dart';
import 'package:products_catelogs/features/shell/presentation/pages/web_shell_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthPage();
        }

        final profileState = ref.watch(userProfileProvider);
        return profileState.when(
          data: (profile) {
            if (profile == null) {
              return _AccountApprovalPendingView(
                title: 'Account Setup In Progress',
                message:
                    'Your account profile is not ready yet. Please contact an admin.',
                onLogout: () => ref.read(authRepositoryProvider).signOut(),
              );
            }
            final profileUid =
                profile['uid']?.toString().trim().isNotEmpty == true
                ? profile['uid'].toString().trim()
                : (profile['_docId']?.toString().trim() ?? '');
            final profileRole = profile['role']?.toString().trim() ?? '';
            if (profileUid != user.uid || profileRole.isEmpty) {
              return _AccountApprovalPendingView(
                title: 'Profile Validation Failed',
                message:
                    'Your profile is missing required access fields. Please contact an admin.',
                onLogout: () => ref.read(authRepositoryProvider).signOut(),
              );
            }
            final approvalStatus =
                profile['approvalStatus']?.toString().trim().toLowerCase() ??
                'approved';
            final isActive = profile['isActive'] is bool
                ? profile['isActive'] as bool
                : true;
            final normalizedRole = profileRole.toLowerCase();
            final isPrivilegedRole =
                normalizedRole.contains('admin') ||
                normalizedRole.contains('developer');
            final requiresApproval = !isPrivilegedRole;
            final isApproved = approvalStatus == 'approved';
            if ((!isApproved && requiresApproval) || !isActive) {
              return _AccountApprovalPendingView(
                title: 'Approval Required',
                message: _approvalMessageForStatus(
                  approvalStatus: approvalStatus,
                  isActive: isActive,
                ),
                onLogout: () => ref.read(authRepositoryProvider).signOut(),
              );
            }
            return const WebShellPage();
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load user profile: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Failed to initialize authentication.',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _approvalMessageForStatus({
  required String approvalStatus,
  required bool isActive,
}) {
  if (!isActive) {
    return 'Your account is currently inactive. Please contact an admin.';
  }
  switch (approvalStatus) {
    case 'pending':
      return 'Your registration is pending admin approval. Please wait.';
    case 'rejected':
      return 'Your registration was rejected. Please contact an admin.';
    default:
      return 'Your account is not approved yet. Please contact an admin.';
  }
}

class _AccountApprovalPendingView extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onLogout;

  const _AccountApprovalPendingView({
    required this.title,
    required this.message,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 38,
                      color: Color(0xFF2E6FBA),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: onLogout,
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
