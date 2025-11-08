import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String apiKey =
      "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";
  final String baseUrl = "https://openrouter.ai/api/v1/chat/completions";

  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
          "HTTP-Referer": "http://localhost:3000", // required by OpenRouter
          "X-Title": "Flutter Chat Demo",
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct",
          "messages": [
            {"role": "user", "content": userMessage}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final choices = data["choices"];
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]["message"];
          if (message != null && message["content"] != null) {
            return message["content"]; // ✅ fixed (no indexing)
          }
        }
        return "No response from model.";
      } else {
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }
}
