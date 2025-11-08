import 'dart:io';
import 'package:chatterly/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadedUrl;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadedUrl = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    final supabaseService = SupabaseService();
    final url = await supabaseService.uploadImage(_selectedImage!, "images"); // 👈 bucket name

    setState(() {
      _uploadedUrl = url;
      _isUploading = false;
    });

    if (url != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Uploaded Successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Image to Supabase")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 200, fit: BoxFit.cover)
            else
              const Text("No image selected", style: TextStyle(color: Colors.white)),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Select Image"),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadImage,
              icon: const Icon(Icons.cloud_upload),
              label: _isUploading
                  ? const Text("Uploading...")
                  : const Text("Upload to Supabase"),
            ),

            const SizedBox(height: 20),

            if (_uploadedUrl != null)
              SelectableText(
                "✅ Uploaded URL:\n$_uploadedUrl",
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
