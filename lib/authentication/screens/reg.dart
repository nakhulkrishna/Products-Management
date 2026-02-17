import 'package:flutter/material.dart';
import 'package:products_catelogs/authentication/provider/authentication_provider.dart';
import 'package:products_catelogs/authentication/screens/authentication_screen.dart';
import 'package:products_catelogs/authentication/widgets/auth_shell.dart';
import 'package:products_catelogs/dashboard/screen/dash_board_reponsive.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingRegistration = true;
  bool _registrationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadRegistrationToggle();
  }

  Future<void> _loadRegistrationToggle() async {
    final userProvider = context.read<UserProvider>();
    final enabled = await userProvider.isRegistrationEnabled(
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      _registrationEnabled = enabled;
      _isCheckingRegistration = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);

    if (_isCheckingRegistration) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_registrationEnabled) {
      return AuthShell(
        title: "Registration Closed",
        subtitle: "New account creation is disabled right now.",
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Back to Login"),
          ),
        ),
      );
    }

    return AuthShell(
      title: "Create account",
      subtitle: "Sign up to continue",
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already have an account? "),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(
              "Sign in",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFieldLabel(context, "Name"),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Name is required';
                if (input.length < 2) return 'Enter at least 2 characters';
                return null;
              },
              decoration: _inputDecoration(
                context,
                hintText: "Your name",
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel(context, "Email"),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Email is required';
                if (!userProvider.isValidEmail(input)) {
                  return 'Enter a valid email';
                }
                return null;
              },
              decoration: _inputDecoration(
                context,
                hintText: "admin@email.com",
                prefixIcon: Icons.mail_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel(context, "Password"),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Password is required';
                if (input.length < 7) return 'At least 7 characters required';
                return null;
              },
              decoration: _inputDecoration(
                context,
                hintText: "********",
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFieldLabel(context, "Confirm Password"),
            const SizedBox(height: 8),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) return 'Please confirm your password';
                if (input != passwordController.text.trim()) {
                  return 'Passwords do not match';
                }
                return null;
              },
              decoration: _inputDecoration(
                context,
                hintText: "********",
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: userProvider.isAuthenticating ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: userProvider.isAuthenticating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Sign Up"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        color: theme.textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
      prefixIcon: Icon(prefixIcon, color: theme.textTheme.bodySmall?.color),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.brightness == Brightness.dark
          ? const Color(0xFF1E1E23)
          : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.register(
      nameController.text,
      emailController.text,
      passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResponsiveDashboard()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userProvider.authMessage ?? "Registration failed"),
      ),
    );
  }
}
