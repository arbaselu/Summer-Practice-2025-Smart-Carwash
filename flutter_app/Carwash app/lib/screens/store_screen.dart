import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class StoreTab extends StatelessWidget {
  const StoreTab({super.key});

  final List<Map<String, dynamic>> packages = const [
    {'title': '1 Jeton', 'price': '4 RON', 'tokens': 1, 'icon': Icons.radio_button_checked, 'amountRon': 4},
    {'title': '3 Jetoane', 'price': '10 RON', 'tokens': 3, 'icon': Icons.radio_button_checked, 'amountRon': 10},
    {'title': '7 Jetoane', 'price': '20 RON', 'tokens': 7, 'icon': Icons.radio_button_checked, 'amountRon': 20},
    {'title': '10 Jetoane', 'price': '27 RON', 'tokens': 10, 'icon': Icons.radio_button_checked, 'amountRon': 27},
    {'title': 'Pachet Premium', 'price': '50 RON', 'tokens': 20, 'icon': Icons.stars, 'amountRon': 50},
    {'title': 'Mega Pack', 'price': '100 RON', 'tokens': 45, 'icon': Icons.rocket, 'amountRon': 100},
  ];

  Future<void> startPayment(BuildContext context, int amountRon, int tokens) async {
    try {
      // Creează payment intent pe server
      final response = await http.post(
        Uri.parse('http://192.168.1.176:5000/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amountRon': amountRon,
          'tokens': tokens,
          'uid': FirebaseAuth.instance.currentUser?.uid,
        }),
      );

      final jsonResponse = jsonDecode(response.body);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse['clientSecret'],
          merchantDisplayName: 'JetWash',
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      // Plata reușită
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plata efectuată cu succes!')),
      );
    } on stripe.StripeException catch (e) {
      if (e.error.code == 'Canceled') {
        // Plata a fost anulata
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plata a fost anulată.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare Stripe: ${e.error.localizedMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Magazin Jetoane')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final item = packages[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(item['icon'], size: 32, color: Colors.blueAccent),
                title: Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('${item['price']} • ${item['tokens']} jetoane'),
                trailing: ElevatedButton(
                  onPressed: () => startPayment(context, item['amountRon'], item['tokens']),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Cumpără'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
