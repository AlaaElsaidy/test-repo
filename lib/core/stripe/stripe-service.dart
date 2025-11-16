import 'dart:convert';

import 'package:http/http.dart' as http;

class StripeService {
  final String supabaseUrl =
      'https://xyhexdrrfxqsnhlqluta.supabase.co/functions/v1/stripe-payment/create-payment-intent';
  final String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5aGV4ZHJyZnhxc25obHFsdXRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2MTQ3MjcsImV4cCI6MjA3ODE5MDcyN30.0uiIn3hs8XW1g79de3m3rWJK2WyQE3m-FST3X78dF4c';

  Future<String> createPaymentIntent(
      {required int amount, bool saveCard = true}) async {
    final response = await http.post(
      Uri.parse(supabaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
      },
      body: json.encode({
        'amount': amount,
        'currency': 'usd',
        if (saveCard) 'setup_future_usage': 'off_session',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to connect to server: ${response.body}');
    }

    final data = json.decode(response.body);
    final clientSecret = data['clientSecret'];
    if (clientSecret == null) throw Exception('Client Secret not found');
    return clientSecret;
  }
}
