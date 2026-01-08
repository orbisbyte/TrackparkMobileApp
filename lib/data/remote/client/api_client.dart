import 'package:dio/dio.dart';
import 'package:driver_tracking_airport/data/remote/client/api_endpoints.dart';

class ApiClient {
  final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: Duration(minutes: 2),
            receiveTimeout: Duration(minutes: 2),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.addAll([
          LogInterceptor(requestBody: true, responseBody: true),
          InterceptorsWrapper(
            onError: (e, handler) {
              return handler.next(e);
            },
          ),
        ]);

  Future<Response> get({
    required String path,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      path,
      queryParameters: query,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  Future<Response> post({
    required String path,
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: body,
      queryParameters: query,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  Future<Response> postForm({
    required String path,
    required FormData data,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: data,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data', ...?headers},
      ),
      cancelToken: cancelToken,
    );
  }

  Future<Response> put({
    required String path,
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _dio.put(
      path,
      data: body,
      queryParameters: query,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  Future<Response> delete({
    required String path,
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: body,
      queryParameters: query,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }
}
