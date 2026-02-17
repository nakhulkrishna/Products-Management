import 'package:flutter/material.dart';
import 'package:products_catelogs/authentication/provider/authentication_provider.dart';
import 'package:products_catelogs/authentication/screens/reg.dart';
import 'package:products_catelogs/authentication/widgets/auth_shell.dart';
import 'package:products_catelogs/dashboard/screen/dash_board_reponsive.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isCheckingRegistration = true;
  bool _registrationEnabled = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);

    return AuthShell(
      title: "Let’s get started",
      subtitle: "Sign in to continue",
      footer: _buildFooter(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Password is required';
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
            const SizedBox(height: 10),
            Row(
              children: [
                Transform.scale(
                  scale: 0.92,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? true);
                    },
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    visualDensity: VisualDensity.compact,
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  "Remember me",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Password reset is not enabled yet."),
                      ),
                    );
                  },
                  child: Text(
                    "Forgot Password",
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                    : const Text("Sign In"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (_isCheckingRegistration) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (!_registrationEnabled) {
      return Text(
        "Registration is currently disabled by admin settings.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RegistrationScreen()),
            );
          },
          child: Text(
            "Sign up",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
    final success = await userProvider.login(
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
      SnackBar(content: Text(userProvider.authMessage ?? "Login failed")),
    );
  }
}
