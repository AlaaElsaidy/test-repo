part of 'sign_up_cubit.dart';

@immutable
sealed class SignUpState {}

final class SignUpInitial extends SignUpState {}

final class SignUpLoading extends SignUpState {}

final class SignUpSuccess extends SignUpState {
  AuthResponse authResponse;

  SignUpSuccess(this.authResponse);
}

final class SignUpFailure extends SignUpState {
  String errorMessage;

  SignUpFailure(this.errorMessage);
}

final class AddFamilyLoading extends SignUpState {}

final class AddFamilySuccess extends SignUpState {}

final class AddFamilyFailure extends SignUpState {
  String errorMessage;

  AddFamilyFailure(this.errorMessage);
}
