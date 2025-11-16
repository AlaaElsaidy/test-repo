part of 'payment_cubit.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final int amount;

  PaymentSuccess(this.amount);
}

class PaymentError extends PaymentState {
  final String message;

  PaymentError(this.message);
}
