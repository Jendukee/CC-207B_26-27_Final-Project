import 'package:orange150_rental/core/config/env.dart';
import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends chat messages to the ai-assistant edge function.
class AssistantService {
  /// Sends [message] and returns the assistant's reply text.
  Future<String> sendMessage(String message) async {
    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      throw Exception('Please enter a message.');
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        Env.aiFunctionName,
        body: {'message': trimmedMessage},
      );

      final data = response.data;

      if (data is Map && data['reply'] is String) {
        return (data['reply'] as String).trim();
      }

      if (data is Map && data['error'] is String) {
        throw Exception(data['error']);
      }

      throw Exception('The assistant returned an unexpected response.');
    } on FunctionException catch (e) {
      final details = e.details;

      if (details is Map && details['error'] is String) {
        throw Exception(details['error']);
      }

      throw Exception(
        'The assistant is unavailable right now. Please try again.',
      );
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to the assistant. Please check your internet connection and try again.',
      );
    }
  }
}