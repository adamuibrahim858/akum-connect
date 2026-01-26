import 'dart:io';
import 'package:dio/dio.dart';
import '../models/vendor_item.dart';
import 'package:http_parser/http_parser.dart';

class VendorService {
  static const String _baseUrl = 'https://akum-connect.mamat.com.ng/api';
  final Dio _dio = Dio();

  VendorService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Accept': 'application/json, */*',
      'User-Agent': 'AkumConnectApp/1.0',
      'Origin': 'https://akum-connect.mamat.com.ng',
      'Referer': 'https://akum-connect.mamat.com.ng/',
    };
    _dio.options.validateStatus = (status) {
      return status! < 500; // Handle 400s manually to inspect body
    };

    // Add logging to inspect everything (Headers, Body, Response)
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<List<VendorItem>> fetchVendors() async {
    try {
      final response = await _dio.get('/vendors');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        final List<dynamic> data = responseData['data'];
        return data.map((json) => VendorItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching items: $e');
    }
  }

  Future<VendorItem> fetchVendorById(int id) async {
    try {
      final response = await _dio.get('/vendors/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        return VendorItem.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to load item details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching item details: $e');
    }
  }

  Future<void> postVendorItem({
    required String name,
    required String email,
    required String phone,
    required String matricNo,
    required String faculty,
    required String department,
    required String itemName,
    required String itemDescription,
    required String itemPrice,
    required String imagePath,
  }) async {
    print('--- DEBUGGING UPLOAD ---');
    print('Image Path: $imagePath');

    if (imagePath.isNotEmpty) {
      final file = File(imagePath);
      final exists = await file.exists();
      print('File Exists (Release Audit): $exists');

      if (exists) {
        print('File Size: ${await file.length()} bytes');
      } else {
        print('[CRITICAL] File does not exist at path!');
      }
    }

    try {
      FormData formData = FormData.fromMap({
        'name': name,
        'email': email,
        'phone': phone,
        'matric_no': matricNo,
        'faculty': faculty,
        'department': department,
        'item_name': itemName,
        'item_description': itemDescription,
        'item_price': itemPrice,
      });

      if (imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          formData.files.add(
            MapEntry(
              'item_image',
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
                contentType: MediaType(
                  'image',
                  'jpeg',
                ), // Explicitly set content type
              ),
            ),
          );
        }
      }

      print('Sending FormData fields: ${formData.fields}');

      final response = await _dio.post('/vendors', data: formData);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        // Strict validation: Check for ID
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic> && data['id'] != null) {
            print('Item created successfully with ID: ${data['id']}');
            return; // Success!
          }
        }

        // Fallback checks
        if (responseData is Map<String, dynamic> &&
            responseData['status'] == true) {
          return; // Success
        }

        throw Exception(
          'Server returned success but data was not saved (No ID).',
        );
      } else if (response.statusCode == 422) {
        final data = response.data;
        String message = data['message'] ?? 'Validation Failed';
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            // Get the first error message from the first key
            final firstKey = errors.keys.first;
            final firstErrorList = errors[firstKey];
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              message = "$message: ${firstErrorList.first}";
            }
          }
        }
        throw Exception(message);
      } else {
        throw Exception('Upload Failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
          'SERVER ERROR BODY: ${e.response?.data}',
        ); // Log the crash details
        if (e.response!.statusCode == 422) {
          // Handle 422 if it comes as DioException (depends on validateStatus)
          // But we setup validateStatus < 500, so it might not throw.
          // Just in case:
          final data = e.response!.data;
          throw Exception(data['message'] ?? 'Validation Error');
        }
        throw Exception(
          'Server Error: ${e.response!.statusCode} ${e.response!.statusMessage}',
        );
      }
      throw Exception('Network Error: ${e.message}');
    } catch (e) {
      throw Exception('Error posting item: $e');
    }
  }
}
