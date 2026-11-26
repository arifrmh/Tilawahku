import 'package:dio/dio.dart';

abstract interface class KajianFeedClient {
  Future<String> fetchXml(String feedUrl);
}

class DioKajianFeedClient implements KajianFeedClient {
  DioKajianFeedClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              responseType: ResponseType.plain,
              headers: const {
                'Accept':
                    'application/rss+xml, application/xml, text/xml;q=0.9, */*;q=0.8',
                'User-Agent': 'Tilawahku/1.0 (Podcast RSS Reader)',
              },
            ),
          );

  final Dio _dio;

  @override
  Future<String> fetchXml(String feedUrl) async {
    try {
      final response = await _dio.get<String>(feedUrl);
      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        throw const FormatException('Server mengembalikan feed RSS kosong.');
      }
      return body;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const KajianNetworkException(
          'Koneksi habis waktu saat memuat feed kajian.',
        );
      }
      final status = error.response?.statusCode;
      if (status != null) {
        throw KajianNetworkException(
          'Server feed kajian merespons status HTTP $status.',
        );
      }
      throw const KajianNetworkException(
        'Tidak dapat terhubung ke server feed kajian. Periksa koneksi internet.',
      );
    }
  }
}

class KajianNetworkException implements Exception {
  const KajianNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}
