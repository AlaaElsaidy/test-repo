import 'dart:io';
import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:supabase/supabase.dart';

class ChatFileService {
  final _client = SupabaseConfig.client;
  final String _bucketName = 'chat-files';

  /// Upload a file/image to chat-files bucket
  Future<String> uploadFile({
    required File file,
    required String chatId,
    required String senderId,
  }) async {
    try {
      print('=== UPLOAD FILE DEBUG ===');
      print('Bucket: $_bucketName');
      print('File path: ${file.path}');
      print('File exists: ${await file.exists()}');
      
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final fileName = 'chat_${chatId}_${senderId}_$timestamp.$extension';
      print('Generated fileName: $fileName');

      final bucket = _client.storage.from(_bucketName);

      // Upload file
      print('Starting upload...');
      await bucket.upload(
        fileName,
        file,
        fileOptions: const FileOptions(
          upsert: false,
          contentType: null, // Auto-detect
        ),
      );
      print('Upload successful!');

      // Get public URL
      final publicUrl = bucket.getPublicUrl(fileName);
      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('=== UPLOAD ERROR ===');
      print('Error: $e');
      rethrow;
    }
  }

  /// Get file URL (already public from uploadFile)
  String getFileUrl(String filePath) {
    // filePath is the full URL from uploadFile
    return filePath;
  }

  /// Delete a file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Extract file name from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) return;

      // Find the bucket path segment
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex == pathSegments.length - 1) return;

      final fileName = pathSegments.sublist(bucketIndex + 1).join('/');

      final bucket = _client.storage.from(_bucketName);
      await bucket.remove([fileName]);
    } catch (e) {
      // Ignore deletion errors (file might not exist)
      print('Error deleting file: $e');
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Get file name from path
  String getFileName(File file) {
    return file.path.split('/').last;
  }
}

