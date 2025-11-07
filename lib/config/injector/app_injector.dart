import '../../core/injector/dio-injector.dart';

class Injector {
  static final api = DioInjector();

  static Future<void> inject() async {
    await api.inject();
  }
}
