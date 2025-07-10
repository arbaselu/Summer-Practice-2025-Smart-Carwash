import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spalatorie_auto/screens/home_screen.dart';
import 'package:spalatorie_auto/screens/register_screen.dart';
import 'package:spalatorie_auto/screens/auth_check.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'stripe_keys.dart';
import 'package:spalatorie_auto/screens/help_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Stripe.publishableKey = StripeKeys.publishableKey;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spalatorie Auto',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthCheck(), //verificare log in
      routes: {
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/ajutor': (context) => const HelpScreen(),
      },
    );
  }
}

