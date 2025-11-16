class PaymentIntentInputModel {
  String amount;
  String currency;

  PaymentIntentInputModel({required this.amount, required this.currency});

  toJson() {
    return {'amount': amount, 'currency': currency};
  }
}
