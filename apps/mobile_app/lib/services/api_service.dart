import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  String get _baseUrl {
    if (kIsWeb) return 'http://192.168.98.183:8080/api';
    // Handle Android Emulator localhost
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8080/api';
      }
    } catch (_) {}
    // Fallback to local network IP provided or localhost
    return 'http://192.168.178.183:8080/api';
  }

  String? _sessionToken;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void setToken(String token) {
    _sessionToken = token;
  }

  String? get token => _sessionToken;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          setToken(data['token']);
        }
        return data;
      }
      throw Exception('Login failed');
    } on DioException catch (e) {
      String msg = e.response?.data?.toString() ?? e.message ?? "Unknown Error";
      if (msg.contains("invalid credentials")) {
        throw Exception("Invalid email or password.");
      }
      throw Exception('API Error: $msg');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          setToken(data['token']);
        }
        return data;
      }
      throw Exception('Registration failed');
    } on DioException catch (e) {
      String msg = e.response?.data?.toString() ?? e.message ?? "Unknown Error";
      if (msg.contains("duplicate key") && msg.contains("users_email_key")) {
        throw Exception("Email is already registered. Please login.");
      } else if (msg.contains("duplicate key") &&
          (msg.contains("users_username_key") || msg.contains("username"))) {
        throw Exception("Username is already taken.");
      }
      throw Exception('API Error: $msg');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getFeed(
      {String? cursor, String? category}) async {
    try {
      final response = await _dio.get('/feed', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (category != null && category != "For You") 'category': category,
      });
      if (response.statusCode == 200) {
        return response.data ?? {'videos': [], 'next_cursor': ''};
      }
      return {'videos': [], 'next_cursor': ''};
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            "Connection Timeout. Is the backend running at $_baseUrl?");
      }
      debugPrint('Feed error: $e');
      return {'videos': [], 'next_cursor': ''};
    } catch (e) {
      debugPrint('Error fetching feed from $_baseUrl: $e');
      return {'videos': [], 'next_cursor': ''};
    }
  }

  Future<Map<String, dynamic>> uploadVideo(
      String filePath, String description) async {
    if (_sessionToken == null)
      throw Exception("Unauthorized: No session token");

    try {
      FormData formData = FormData.fromMap({
        'description': description,
        'video': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post('/upload',
          data: formData,
          options: Options(headers: {
            'Authorization': 'Bearer $_sessionToken',
          }));

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Upload failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    if (_sessionToken == null)
      throw Exception("Unauthorized: No session token");

    try {
      final response = await _dio.get('/profile',
          options: Options(headers: {
            'Authorization': 'Bearer $_sessionToken',
          }));

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch profile');
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<Map<String, dynamic>> getExternalProfile(String userId) async {
    if (_sessionToken == null)
      throw Exception("Unauthorized: No session token");

    try {
      final response = await _dio.get('/profile',
          queryParameters: {'user_id': userId},
          options: Options(headers: {
            'Authorization': 'Bearer $_sessionToken',
          }));

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch external profile');
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<void> followUser(String followeeId) async {
    if (_sessionToken == null)
      throw Exception("Unauthorized: No session token");
    try {
      final response = await _dio.post(
        '/follow',
        data: {'followee_id': followeeId},
        options: Options(headers: {'Authorization': 'Bearer $_sessionToken'}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to follow user');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<void> unfollowUser(String followeeId) async {
    if (_sessionToken == null)
      throw Exception("Unauthorized: No session token");
    try {
      final response = await _dio.post(
        '/unfollow',
        data: {'followee_id': followeeId},
        options: Options(headers: {'Authorization': 'Bearer $_sessionToken'}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow user');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<List<dynamic>> getComments(String videoId) async {
    try {
      final response =
          await _dio.get('/comments', queryParameters: {'video_id': videoId});
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<void> postComment(String videoId, String content) async {
    if (_sessionToken == null)
      throw Exception("Unauthorized: No session token");
    try {
      final response = await _dio.post(
        '/comments',
        data: {'video_id': videoId, 'content': content},
        options: Options(headers: {'Authorization': 'Bearer $_sessionToken'}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to post comment');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<List<dynamic>> searchVideos(String query) async {
    try {
      final response = await _dio.get('/search', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<bool> toggleLike(String videoId) async {
    if (_sessionToken == null)
      throw Exception("Unauthorized: No session token");
    try {
      final response = await _dio.post(
        '/like',
        data: {'video_id': videoId},
        options: Options(headers: {'Authorization': 'Bearer $_sessionToken'}),
      );
      if (response.statusCode == 200) {
        return response.data['is_liked'] as bool;
      }
      throw Exception('Failed to toggle like');
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<List<dynamic>> getFollowers(String userId) async {
    try {
      final response =
          await _dio.get('/followers', queryParameters: {'user_id': userId});
      return response.data ?? [];
    } catch (e) {
      debugPrint('Followers error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getFollowing(String userId) async {
    try {
      final response =
          await _dio.get('/following', queryParameters: {'user_id': userId});
      return response.data ?? [];
    } catch (e) {
      debugPrint('Following error: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return List<String>.from(response.data ?? []);
    } catch (e) {
      debugPrint('Categories error: $e');
      return ["For You", "Comedy", "Music", "Gaming", "Tech", "Travel", "Food"];
    }
  }

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('/messages');
      return response.data ?? [];
    } catch (e) {
      debugPrint('Conversations error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get('/messages',
          queryParameters: {'conversation_id': conversationId});
      return response.data ?? [];
    } catch (e) {
      debugPrint('Messages error: $e');
      return [];
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    try {
      final response = await _dio.post('/messages', data: {
        'conversation_id': conversationId,
        'content': content,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Send message error: $e');
      return false;
    }
  }

  Future<bool> sendMessageToUser(String receiverId, String content) async {
    try {
      final response = await _dio.post('/messages/send_to_user', data: {
        'receiver_id': receiverId,
        'content': content,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Send to user error: $e');
      return false;
    }
  }

  Future<int> getWalletBalance() async {
    if (_sessionToken == null) return 0;
    try {
      final response = await _dio.get('/wallet/balance');
      return (response.data['balance'] ?? 0) as int;
    } catch (e) {
      debugPrint('Balance error: $e');
      return 0;
    }
  }

  Future<bool> reportVideo(String videoId, String reason) async {
    if (_sessionToken == null) return false;
    try {
      final response = await _dio.post('/report', data: {
        'video_id': videoId,
        'reason': reason,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Report error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getTrendingVideos() async {
    try {
      final response = await _dio.get('/discover');
      return response.data ?? [];
    } catch (e) {
      debugPrint('Trending error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getNotifications() async {
    if (_sessionToken == null) return [];
    try {
      final response = await _dio.get('/notifications');
      return response.data ?? [];
    } catch (e) {
      debugPrint('Notifications error: $e');
      return [];
    }
  }

  Future<bool> sendGift(String receiverId, int amount) async {
    if (_sessionToken == null) return false;
    try {
      final response = await _dio.post('/wallet/gift', data: {
        'receiver_id': receiverId,
        'amount': amount,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Gift error: $e');
      return false;
    }
  }
}


