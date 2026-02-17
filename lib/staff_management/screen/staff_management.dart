import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:products_catelogs/staff_management/provider/provider.dart';
import 'package:products_catelogs/theme/widgets/app_components.dart';
import 'package:products_catelogs/theme/widgets/reference_scaffold.dart';
import 'package:provider/provider.dart';

class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    return ReferenceScaffold(
      title: "Add Staff",
      subtitle: "Create salesman login",
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AppSectionCard(
          title: "Staff Credentials",
          subtitle: "Create login details for a new staff member",
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person),
                  errorText: provider.submitted && provider.username.isEmpty
                      ? 'Username required'
                      : null,
                ),
                onChanged: provider.setUsername,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Iconsax.direct),
                  errorText: provider.submitted && provider.email.isEmpty
                      ? 'Email required'
                      : null,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: provider.setEmail,
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: provider.obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Iconsax.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      provider.obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: provider.togglePasswordVisibility,
                  ),
                  errorText: provider.submitted && provider.password.length < 7
                      ? 'Password must be at least 7 characters'
                      : null,
                ),
                onChanged: provider.setPassword,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    provider.markSubmitted();
                    if (!provider.validateFields()) return;

                    try {
                      await provider.submitStaff();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Staff added successfully')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Text("Add Sales Man"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
