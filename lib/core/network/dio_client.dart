import 'package:dio/dio.dart';

class DioClient {
  DioClient() {
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
  }
  final Dio dio = Dio();
}
