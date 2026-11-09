import 'package:chatkuy/data/models/chat_message_model.dart';

/// Presentation helpers shared by chat stores and data services.
///
/// Keeping these mappings in one place prevents message previews, search
/// labels, and room summaries from drifting apart as message types evolve.
abstract final class ChatMessagePresentation {
  static String typeLabel(MessageType type) {
    return switch (type) {
      MessageType.image => 'Foto',
      MessageType.video => 'Video',
      MessageType.call => 'Panggilan',
      MessageType.file => 'Dokumen',
      MessageType.contact => 'Kontak',
      MessageType.audio => 'Pesan suara',
      MessageType.text => 'Pesan',
    };
  }

  static String fallbackText(MessageType type) {
    return type == MessageType.text ? '' : typeLabel(type);
  }

  static String resolveText(String? text, MessageType type) {
    final cleanText = text?.trim();
    return cleanText?.isNotEmpty == true ? cleanText! : fallbackText(type);
  }

  static String? preview(ChatMessageModel? message) {
    if (message == null) return null;
    final value = resolveText(message.text, message.type);
    return value.isEmpty ? null : value;
  }
}
