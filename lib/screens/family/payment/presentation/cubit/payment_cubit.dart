import 'package:bloc/bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../data/payment-repo.dart';

part 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;

  PaymentCubit(this.repository) : super(PaymentInitial());

  Future<void> pay({
    required int amount,
    required String cardHolder,
    bool saveCard = true,
  }) async {
    emit(PaymentLoading());
    try {
      await repository.payWithCard(
        amount: amount,
        cardHolder: cardHolder,
        saveCard: saveCard,
      );
      emit(PaymentSuccess(amount));
    } on StripeException catch (e) {
      emit(PaymentError(e.error.localizedMessage ?? 'Payment failed'));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
