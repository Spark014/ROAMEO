import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploader {
  static Future<String> uploadImage(File file) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null ||
        cloudName.isEmpty ||
        uploadPreset == null ||
        uploadPreset.isEmpty) {
      throw Exception(
          'Cloudinary not configured: CLOUDINARY_CLOUD_NAME / CLOUDINARY_UPLOAD_PRESET missing in .env');
    }

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(
          'Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary response missing secure_url: $body');
    }
    return secureUrl;
  }
}
