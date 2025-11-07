import 'package:get_it/get_it.dart';

abstract class InjectorBase {
  GetIt get getIt;

  Future<void> inject();
}
