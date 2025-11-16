import 'package:alzcare/config/router/routes.dart';
import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:alzcare/config/shared/widgets/loading.dart';
import 'package:alzcare/core/stripe/stripe-service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../../config/shared/widgets/custom-button.dart';
import '../../../../../config/shared/widgets/decore-circle.dart';
import '../../../../../config/shared/widgets/error-dialoge.dart';
import '../../../../../config/shared/widgets/success-dialoge.dart';
import '../../data/payment-repo.dart';
import '../cubit/payment_cubit.dart';
import '../widgets/amount-section.dart';
import '../widgets/card-input-section.dart';
import '../widgets/card-preview.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _nameController = TextEditingController();
  final CardFormEditController _cardFormController = CardFormEditController();

  CardFieldInputDetails? _cardDetails;
  bool _cardComplete = false;
  bool _saveCard = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));

    _cardFormController.addListener(() {
      final d = _cardFormController.details;
      setState(() {
        _cardDetails = d;
        _cardComplete = d?.complete ?? false;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardFormController.dispose();
    super.dispose();
  }

  String get _maskedNumber {
    final last4 = _cardDetails?.last4;
    return last4 != null ? '**** **** **** $last4' : '**** **** **** ****';
  }

  String get _expiryFromForm {
    final m = _cardDetails?.expiryMonth;
    final y = _cardDetails?.expiryYear;
    if (m == null || y == null) return 'MM/YY';
    final mm = m.toString().padLeft(2, '0');
    final yy = (y % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    final amount = ModalRoute.of(context)?.settings.arguments as int? ?? 150;
    double width = MediaQuery.sizeOf(context).width;
    return BlocProvider(
      create: (context) => PaymentCubit(PaymentRepository(StripeService())),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
                top: -width * 0.25,
                left: -width * 0.15,
                child: DecorCircle(size: width * 0.7)),
            Positioned(
                bottom: -width * 0.3,
                right: -width * 0.2,
                child: DecorCircle(size: width * 0.9)),
            SafeArea(
              child: BlocConsumer<PaymentCubit, PaymentState>(
                listener: (context, state) {
                  if (state is PaymentError) {
                    showErrorDialog(
                        context: context,
                        title: 'Payment Failed',
                        error: state.message);
                  }
                  if (state is PaymentSuccess) {
                    showSuccessDialog(
                        title: 'Payment Successful!',
                        description:
                            'You have successfully paid \$${state.amount}',
                        context: context,
                        onClick: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (route) => false,
                          );
                        });
                  }
                },
                builder: (context, state) {
                  final isLoading = state is PaymentLoading;

                  return Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: context.w(18))
                            .copyWith(
                          top: context.h(22),
                          bottom: MediaQuery.of(context).viewInsets.bottom +
                              context.h(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Payment Details",
                              style: TextStyle(
                                color: const Color(0xFF0E3E3B),
                                fontSize: context.sp(26),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: context.h(6)),
                            Text(
                              "Enter your card information to proceed",
                              style: TextStyle(
                                color: const Color(0xFF7EA9A3),
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                              ),
                            ),
                            SizedBox(height: context.h(18)),
                            CardPreview(
                              masked: _maskedNumber,
                              holder: _nameController.text.isEmpty
                                  ? "Cardholder"
                                  : _nameController.text,
                              expiry: _expiryFromForm,
                            ),
                            SizedBox(height: context.h(22)),
                            CardInputSection(
                              onChange: (v) {
                                setState(() => _saveCard = v ?? true);
                              },
                              cardFormEditController: _cardFormController,
                              saveCard: _saveCard,
                              nameController: _nameController,
                              onCardChange: (details) {
                                setState(() {
                                  _cardDetails = details;
                                  _cardComplete = details?.complete ?? false;
                                });
                              },
                            ),
                            SizedBox(height: context.h(18)),
                            AmountSection(
                              amount: 150,
                            ),
                            SizedBox(height: context.h(20)),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                  onClick: () {
                                    final cardHolder =
                                        _nameController.text.trim();
                                    if (!_cardComplete) {
                                      showErrorDialog(
                                          title: 'Payment Failed',
                                          context: context,
                                          error:
                                              'Please enter complete card details.');
                                      return;
                                    }
                                    if (cardHolder.isEmpty) {
                                      showErrorDialog(
                                          context: context,
                                          title: 'Payment Failed',
                                          error:
                                              'Please enter the cardholder name.');
                                      return;
                                    }
                                    context.read<PaymentCubit>().pay(
                                          amount: amount,
                                          cardHolder: cardHolder,
                                          saveCard: _saveCard,
                                        );
                                  },
                                  text: isLoading ? "Loading..." : "Pay Now"),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        Positioned.fill(
                          child: AbsorbPointer(
                            absorbing: true,
                            child: Container(
                              color: Colors.black.withOpacity(0.1),
                              child: const Center(child: LoadingPage()),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helpers
}
