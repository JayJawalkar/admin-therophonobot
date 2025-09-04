import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String _blockUserUrl =
      "https://us-central1-therophonobot-d22eb.cloudfunctions.net/blockUser";

  /// Blocks a user by UID
  static Future<Map<String, dynamic>> blockUser(String uid) async {
    try {
      final response = await http.post(
        Uri.parse(_blockUserUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"uid": uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          return {"success": true, "message": data["message"]};
        } else {
          return {"success": false, "error": data["error"] ?? "Unknown error"};
        }
      } else {
        return {
          "success": false,
          "error": "Server error: ${response.statusCode} ${response.reasonPhrase}"
        };
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }
}
