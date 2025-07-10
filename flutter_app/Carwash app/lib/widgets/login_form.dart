import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _login() {
    String email = emailController.text;
    String password = passwordController.text;

    // TODO: autentificare reală
    print('Email: $email, Parolă: $password');
  }

  void _loginWithGoogle() {
    print('Logare cu Google (de implementat)');
  }

  void _loginWithFacebook() {
    print('Logare cu Facebook (de implementat)');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Parolă'),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _login,
          child: const Text('Autentificare'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {}, // TODO: înregistrare
          child: const Text('Nu ai cont? Înregistrează-te'),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Continuă cu Google'),
          onPressed: _loginWithGoogle,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.facebook),
          label: const Text('Continuă cu Facebook'),
          onPressed: _loginWithFacebook,
        ),
      ],
    );
  }
}
