import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String docUrl;

  const DocumentViewerScreen({
    super.key,
    required this.docUrl,
  });

  // ✅ Function to detect file type
  Icon _getFileIcon(String fileName) {
    final extension = fileName.split(".").last.toLowerCase();

    switch (extension) {
      case "pdf":
        return const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red);
      case "doc":
      case "docx":
        return const Icon(Icons.description, size: 80, color: Colors.blue);
      case "xls":
      case "xlsx":
        return const Icon(Icons.grid_on, size: 80, color: Colors.green);
      case "ppt":
      case "pptx":
        return const Icon(Icons.slideshow, size: 80, color: Colors.orange);
      case "txt":
        return const Icon(Icons.notes, size: 80, color: Colors.grey);
      default:
        return const Icon(Icons.insert_drive_file, size: 80, color: Colors.teal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = docUrl.split("/").last; // Extract filename

    return Scaffold(
      backgroundColor: Colors.white, // ✅ White background for whole screen
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Document",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ File icon based on type
              _getFileIcon(fileName),
              const SizedBox(height: 20),

              // File name
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Open in browser
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text(
                  "Open Document",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(docUrl);
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Could not open document")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
