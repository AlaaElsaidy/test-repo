part of 'login_cubit.dart';

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  AuthResponse authResponse;

  LoginSuccess(this.authResponse);
}

final class LoginFailure extends LoginState {
  String errorMessage;

  LoginFailure(this.errorMessage);
}

final class GetUserLoading extends LoginState {}

final class GetUserSuccess extends LoginState {
  Map<String, dynamic>? user;

  GetUserSuccess(this.user);
}

final class GetUserFailure extends LoginState {
  String errorMessage;

  GetUserFailure(this.errorMessage);
}
