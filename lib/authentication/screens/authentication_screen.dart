import 'package:flutter/material.dart';
import 'package:products_catelogs/authentication/provider/authentication_provider.dart';
import 'package:products_catelogs/dashboard/screen/dashboard_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String email = emailController.text.trim();
                  String password = passwordController.text.trim();

                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter email & password")),
                    );
                    return;
                  }

                  bool success = await userProvider.login(email, password);
                  if (success) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DashboardScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid credentials")),
                    );
                  }
                },
                child: const Text("Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
