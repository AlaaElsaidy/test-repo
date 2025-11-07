import 'package:dio/dio.dart';

abstract class BaseConsumer {
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  });

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  });

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  });

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  });
}
