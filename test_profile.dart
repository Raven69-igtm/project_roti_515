import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://roti515-api.vercel.app/api';
  final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODAxNjA1NzYsInJvbGUiOiJwZWxhbmdnYW4iLCJzdWIiOjE0fQ.6vFiEftHn-IvZtAKFcer88JvsSF4LoAEPtm3oOljnBU';
  
  final profileRes = await http.get(
    Uri.parse('$baseUrl/profile'),
    headers: {
      "Authorization": "Bearer $token"
    }
  );
  
  print("Get Profile: ${profileRes.body}");
}
