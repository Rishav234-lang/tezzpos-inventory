import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio dio;
  final AuthLocalDataSource? _tokenSource;

  DioClient({AuthLocalDataSource? tokenSource}) : _tokenSource = tokenSource {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_tokenSource != null) {
            final token = await _tokenSource.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          if (kDebugMode) {
            print('REQUEST: ${options.method} ${options.uri}');
            print('HEADERS: ${options.headers}');
            print('BODY: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('RESPONSE: ${response.statusCode} ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('ERROR: ${error.response?.statusCode} ${error.message}');
            print('ERROR DATA: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
