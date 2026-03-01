import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class UploadService {
  final Dio _dio = Dio();
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8080/api';
      }
    } catch (_) {}
    return 'http://192.168.178.183:8080/api';
  }

  Future<void> uploadVideo({
    required XFile file,
    required String fileName,
    required Function(double) onProgress,
    required VoidCallback onComplete,
    required Function(String) onError,
  }) async {
    try {
      final token = ApiService().token;
      if (token == null) {
        throw Exception("You must be logged in to upload a video.");
      }

      FormData formData = FormData.fromMap({
        'description': 'Mobile Phone Video Upload 🚀',
        'video': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      await _dio.post(
        '$_baseUrl/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            onProgress(sent / total);
          }
        },
      );

      onComplete();
    } catch (e) {
      if (e is DioException) {
        onError(
            e.response?.data?.toString() ?? e.message ?? "Unknown Dio Error");
      } else {
        onError(e.toString());
      }
    }
  }
}


