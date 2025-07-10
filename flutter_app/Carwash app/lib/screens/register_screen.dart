import 'package:flutter/material.dart';
import 'package:spalatorie_auto/services/auth_service.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Înregistrare')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nume'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Parolă'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final user = await AuthService.registerWithEmail(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                  nameController.text.trim(),
                );

                if (user != null && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Înregistrare eșuată')),
                  );
                }
              },
              child: const Text('Înregistrează-te'),
            ),
          ],
        ),
      ),
    );
  }
}
