// Sends chat messages to the ai-assistant Supabase Edge Function, which
// calls Gemini (the API key never ships in the app). Returns the reply
// text or throws with a message the screen can show.
//
// OWNER: Member 1.

import 'package:orange150_rental/core/config/env.dart';
import 'package:orange150_rental/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A safe, user-facing assistant request error.
class AssistantException implements Exception {
  const AssistantException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sends chat messages to the ai-assistant edge function.
class AssistantService {
  /// Sends [message] and returns the assistant's reply text.
  Future<String> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw const AssistantException('Please enter a message.');
    }

    final functionName = Env.aiFunctionName.trim().toLowerCase();
    if (functionName.isEmpty) {
      throw const AssistantException(
        'The assistant is not configured. Check AI_FUNCTION_NAME in env.json.',
      );
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        functionName,
        body: {'message': trimmedMessage},
      );
      final data = response.data;

      if (data is Map && data['reply'] is String) {
        final reply = (data['reply'] as String).trim();
        if (reply.isNotEmpty) return reply;
      }

      if (data is Map && data['error'] is String) {
        throw AssistantException(data['error'] as String);
      }

      throw const AssistantException(
        'The assistant returned an empty or unexpected response.',
      );
    } on AssistantException {
      rethrow;
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] is String) {
        throw AssistantException(details['error'] as String);
      }
      if (error.status == 404) {
        throw const AssistantException(
          'The assistant function was not found. Check its name and deploy it.',
        );
      }
      if (error.status == 401 || error.status == 403) {
        throw const AssistantException(
          'The assistant request was not authorized. Check the Supabase '
          'function deployment and project configuration.',
        );
      }
      throw const AssistantException(
        'The assistant is temporarily unavailable. Please try again.',
      );
    } catch (_) {
      throw const AssistantException(
        'Could not reach the assistant. Check your connection and try again.',
      );
    }
  }
}
