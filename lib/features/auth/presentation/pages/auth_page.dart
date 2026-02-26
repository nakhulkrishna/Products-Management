import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/features/auth/application/auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _roleController = TextEditingController(text: 'Sales Manager');
  final _phoneController = TextEditingController(text: '+974 5500 1122');
  final _regionController = TextEditingController(text: 'Doha');
  final _departmentController = TextEditingController(text: 'Commercial');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isSubmitting = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3E8F1)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLogin ? 'Login' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Sign in to continue managing products.'
                        : 'Create a manager account to access the dashboard.',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _fullNameController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Sales Manager',
                      ),
                      validator: (value) {
                        if (_isLogin) return null;
                        final text = value?.trim() ?? '';
                        if (text.length < 3) {
                          return 'Enter at least 3 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _roleController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Role'),
                      validator: (value) {
                        if (_isLogin) return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Role is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) {
                        if (_isLogin) return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Phone is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _regionController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Region'),
                      validator: (value) {
                        if (_isLogin) return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Region is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _departmentController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Department'),
                      validator: (value) {
                        if (_isLogin) return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Department is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'manager@company.com',
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return 'Email is required.';
                      final isValidEmail = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(text);
                      if (!isValidEmail) return 'Enter a valid email address.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isSubmitting,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: _isLogin ? 'Enter password' : 'Minimum 8 chars',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) return 'Password is required.';
                      if (!_isLogin && text.length < 8) {
                        return 'Use at least 8 characters.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting ? null : _resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'Login' : 'Create Account'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? 'Don\'t have an account?'
                            : 'Already have an account?',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _passwordController.clear();
                                  if (!_isLogin) {
                                    _roleController.text = 'Sales Manager';
                                    _phoneController.text = '+974 5500 1122';
                                    _regionController.text = 'Doha';
                                    _departmentController.text = 'Commercial';
                                  }
                                });
                              },
                        child: Text(_isLogin ? 'Create one' : 'Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();
    final role = _roleController.text.trim();
    final phone = _phoneController.text.trim();
    final region = _regionController.text.trim();
    final department = _departmentController.text.trim();

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await repo.signIn(email: email, password: password);
      } else {
        await repo.createAccount(
          fullName: fullName,
          email: email,
          password: password,
          role: role,
          phone: phone,
          region: region,
          department: department,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyFirebaseMessage(e), isError: true);
    } catch (e) {
      _showMessage('Authentication failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email first.', isError: true);
      return;
    }

    final isValidEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValidEmail) {
      _showMessage('Enter a valid email address.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      _showMessage('Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyFirebaseMessage(e), isError: true);
    } catch (e) {
      _showMessage('Could not send reset email: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _friendlyFirebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? const Color(0xFFB42318) : null,
      ),
    );
  }
}
