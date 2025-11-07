import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'BaseConsumer.dart';

class DioConsumer implements BaseConsumer {
  DioConsumer(this.dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final locale = WidgetsBinding.instance.platformDispatcher.locale;
          options.headers["Accept-Language"] = locale.languageCode;
          options.headers["API-Key"] = "sk_test_51H6x9YZvP7aQx93Lz4bX1tM9uQw";
          return handler.next(options);
        },
      ),
    );
  }

  final Dio dio;

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    final response = await dio.delete<T>(
      path,
      queryParameters: queryParameters,
      data: data,
    );
    return response;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return response;
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.post<T>(
      path,
      data: data,
      options: Options(headers: headers),
      queryParameters: queryParameters,
    );
    return response;
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response;
  }
}
