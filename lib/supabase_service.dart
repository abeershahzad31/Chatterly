import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Upload Image (bucket = images)
  Future<String?> uploadImage(File imageFile, String s) async {
    try {
      const bucket = "images";
      
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}";

      final response = await _client.storage.from(bucket).upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      if (response.isEmpty) {
        throw Exception("Upload failed: Empty response");
      }

      return _client.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      print("❌ Image upload error: $e");
      return null;
    }
  }

/// Upload Voice (bucket = voices)
Future<String?> uploadVoice(File voiceFile, String s) async {
  try {
    const bucket = "voices"; // ✅ New bucket
    final fileName = "voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

    final response = await _client.storage.from(bucket).upload(
          fileName,
          voiceFile,
          fileOptions: const FileOptions(upsert: true),
        );

    if (response.isEmpty) {
      throw Exception("Upload failed: Empty response");
    }

    return _client.storage.from(bucket).getPublicUrl(fileName);
  } catch (e) {
    print("❌ Voice upload error: $e");
    return null;
  }
}

  Future uploadProfileImage(File file, String uid) async {}

    }
  


