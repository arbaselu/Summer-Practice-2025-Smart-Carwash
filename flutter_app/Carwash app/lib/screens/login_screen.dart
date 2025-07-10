import 'package:flutter/material.dart';
import 'package:spalatorie_auto/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      resizeToAvoidBottomInset: true, // permite scroll cand apare tastatura
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Parolă'),
            ),
            const SizedBox(height: 24),

            /// Buton Autentificare cu Email
            ElevatedButton(
              onPressed: () async {
                try {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  if (credential.user != null && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                } on FirebaseAuthException catch (e) {
                  String mesaj = 'Eroare la autentificare.';
                  if (e.code == 'user-not-found') {
                    mesaj = 'Nu există un utilizator cu acest email.';
                  } else if (e.code == 'wrong-password') {
                    mesaj = 'Parolă incorectă.';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mesaj)),
                  );
                }
              },
              child: const Text('Autentificare'),
            ),

            const SizedBox(height: 16),
            const Center(child: Text('sau')),
            const SizedBox(height: 16),

            /// Buton Google
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final User? user = await AuthService.signInWithGoogle();

                if (user != null && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Autentificare Google eșuată')),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/btn_google_signin.png', height: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Buton Facebook
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final user = await AuthService.signInWithFacebook();
                if (user != null && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Autentificare Facebook eșuată')),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/facebook_logo.png', height: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Facebook',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Nu ai cont? Înregistrează-te'),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: navigare către ResetPasswordScreen
                    },
                    child: const Text('Ai uitat parola?'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


