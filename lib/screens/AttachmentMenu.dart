import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/chat_provider.dart';

class AttachmentMenu extends StatelessWidget {
  final ImagePicker picker;
  final String receiverId;
  final String chatId;

  const AttachmentMenu({
    super.key,
    required this.picker,
    required this.receiverId,
    required this.chatId, required Future<void> Function() onPickImage, required String senderId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Share Content",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 📸 Camera
                _buildOption(
                  context,
                  Icons.camera_alt_outlined,
                  "Camera",
                  "Take a photo",
                  () => _pickImage(context, ImageSource.camera),
                ),

                // 📄 Documents
                _buildOption(
                  context,
                  Icons.insert_drive_file_outlined,
                  "Documents",
                  "Share your files",
                  () => _pickDocument(context),
                ),

                // 🖼️ Media (Gallery)
                _buildOption(
                  context,
                  Icons.image_outlined,
                  "Media",
                  "Share photos and videos",
                  () => _pickImage(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  /// 📸 Pick Image (Camera or Gallery)
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final imageFile = File(picked.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';

      final supabase = Supabase.instance.client;
      await supabase.storage.from('images').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);

      await chatProvider.sendMessage(
        receiverId: receiverId,
        chatId: chatId,
        text: publicUrl, // 🔗 store link in Firestore
        imageUrl: null,
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Failed to send image: $e");
      debugPrint(stackTrace.toString());
    }
  }

  /// 📄 Pick and Upload Document
  Future<void> _pickDocument(BuildContext context) async {
    try {
      final chatProvider = context.read<ChatProvider>();

      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.single.path == null) {
        debugPrint("❌ No document selected.");
        return;
      }

      final docFile = File(result.files.single.path!);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(docFile.path)}';

      final supabase = Supabase.instance.client;
      await supabase.storage.from('documents').upload(
            fileName,
            docFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          supabase.storage.from('documents').getPublicUrl(fileName);

      await chatProvider.sendMessage(
        receiverId: receiverId,
        chatId: chatId,
        text: publicUrl, // 🔗 store link in Firestore
        imageUrl: null,
      );

      debugPrint("✅ Document sent: $publicUrl");
    } catch (e, stackTrace) {
      debugPrint("❌ Failed to send document: $e");
      debugPrint(stackTrace.toString());
    }
  }
}

