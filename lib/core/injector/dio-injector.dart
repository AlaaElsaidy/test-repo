import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../config/injector/injector_base.dart';
import '../dio/BaseConsumer.dart';
import '../dio/Dio_consumer.dart';

class DioInjector extends InjectorBase {
  @override
  GetIt get getIt => GetIt.instance;

  @override
  Future<void> inject() async {
    getIt.registerLazySingleton<BaseConsumer>(() => DioConsumer(Dio()));
  }
}
