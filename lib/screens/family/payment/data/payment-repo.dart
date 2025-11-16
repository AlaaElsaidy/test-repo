import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../core/stripe/stripe-service.dart';

class PaymentRepository {
  final StripeService stripeService;

  PaymentRepository(this.stripeService);

  Future<void> payWithCard({
    required int amount,
    required String cardHolder,
    bool saveCard = true,
  }) async {
    final clientSecret = await stripeService.createPaymentIntent(
        amount: amount, saveCard: saveCard);

    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: const PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(),
      ),
    );
  }
}
